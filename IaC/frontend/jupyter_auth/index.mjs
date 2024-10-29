import { SSMClient, GetParameterCommand } from '@aws-sdk/client-ssm';
import { CognitoIdentityProviderClient, AdminInitiateAuthCommand } from '@aws-sdk/client-cognito-identity-provider';
import jwt from 'jsonwebtoken';
import axios from 'axios';
import jwkToPem from 'jwk-to-pem';

let ssmClient;
let cognitoClient;

let REGION, USER_POOL_ID, CLIENT_ID, JWK_URL;
let pemCache = {};
let initialized = false;

async function initializeCognitoConfig() {
    if (!initialized) {
        ssmClient = new SSMClient({ region: "us-east-1" });
        REGION = await getParameter('/callisto/cognito_region');
        USER_POOL_ID = await getParameter('/callisto/cognito_user_pool_id');
        CLIENT_ID = await getParameter('/callisto/cognito_client_id');

        cognitoClient = new CognitoIdentityProviderClient({ region: REGION });
        JWK_URL = `https://cognito-idp.${REGION}.amazonaws.com/${USER_POOL_ID}/.well-known/jwks.json`;

        await cacheJwksAsPem();

        initialized = true;
    }
}

async function getParameter(name) {
    const command = new GetParameterCommand({ Name: name, WithDecryption: true });
    const response = await ssmClient.send(command);
    return response.Parameter.Value;
}

async function cacheJwksAsPem() {
    const response = await axios.get(JWK_URL);
    const jwks = response.data.keys;
    jwks.forEach((jwk) => {
        pemCache[jwk.kid] = jwkToPem(jwk);
    });
}

export const handler = async (event) => {
    await initializeCognitoConfig();

    const request = event.Records[0].cf.request;
    const headers = request.headers;

    const uuid = extractUuidFromPath(request.uri);

    const idToken = extractTokenFromCookie(headers, 'idToken');
    const accessToken = extractTokenFromCookie(headers, 'accessToken');
    const refreshToken = extractTokenFromCookie(headers, 'refreshToken');

    const tokenValidationResult = await isTokenValid(idToken, uuid);
    if (tokenValidationResult === "TokenExpired" && refreshToken) {
        try {
            const newTokens = await refreshTokensWithAwsSdk(refreshToken);
            setTokensInCookies(newTokens, headers);
            return request;
        } catch (error) {
            return errorResponse("Failed to refresh token");
        }
    } else if (tokenValidationResult !== true) {
        return errorResponse(tokenValidationResult === "TokenUUIDMismatch" ? "Token UUID mismatch" : "Invalid token");
    }

    return request;
};

async function refreshTokensWithAwsSdk(refreshToken) {
    const params = {
        AuthFlow: 'REFRESH_TOKEN_AUTH',
        ClientId: CLIENT_ID,
        UserPoolId: USER_POOL_ID,
        AuthParameters: {
            REFRESH_TOKEN: refreshToken,
        },
    };

    const command = new AdminInitiateAuthCommand(params);
    const response = await cognitoClient.send(command);

    if (response.AuthenticationResult) {
        return {
            id_token: response.AuthenticationResult.IdToken,
            access_token: response.AuthenticationResult.AccessToken,
        };
    } else {
        throw new Error('Token refresh failed');
    }
}

function extractUuidFromPath(path) {
    const match = path.match(/\/api\/jupyter-access\/([a-f0-9-]{36})-\d+/);
    return match ? match[1] : null;
}

function extractTokenFromCookie(headers, tokenName) {
    const cookies = headers.cookie ? headers.cookie[0].value.split('; ') : [];
    const tokenCookie = cookies.find((cookie) => cookie.startsWith(`${tokenName}=`));
    return tokenCookie ? tokenCookie.split('=')[1] : null;
}

async function isTokenValid(token, uuid) {
    const decoded = jwt.decode(token, { complete: true });
    const kid = decoded.header.kid;

    const publicKey = pemCache[kid];
    if (!publicKey) throw new Error('Public key not found');

    try {
        const verifiedToken = jwt.verify(token, publicKey, { algorithms: ['RS256'] });
        if (verifiedToken.sub !== uuid) return "TokenUUIDMismatch";
        return true;
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return "TokenExpired"
        }
        return false;
    }
}

function setTokensInCookies(tokens, headers) {
    const cookies = [
        `idToken=${tokens.id_token}; Path=/; Secure; HttpOnly`,
        `accessToken=${tokens.access_token}; Path=/; Secure; HttpOnly`
    ];
    headers['set-cookie'] = cookies;
}

function errorResponse(message) {
    return {
        status: '401',
        statusDescription: 'Forbidden',
        body: message || 'Unauthorized',
    };
}