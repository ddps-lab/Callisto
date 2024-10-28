import { SSMClient, GetParameterCommand } from '@aws-sdk/client-ssm';
import { CognitoIdentityProviderClient, AdminInitiateAuthCommand } from '@aws-sdk/client-cognito-identity-provider';
import jwt from 'jsonwebtoken';

let ssmClient;
let cognitoClient;

let REGION, USER_POOL_ID, CLIENT_ID;
let initialized = false;

async function initializeCognitoConfig() {
    if (!initialized) {
        ssmClient = new SSMClient({ region: "us-east-1" });
        REGION = await getParameter('/callisto/cognito_region');
        USER_POOL_ID = await getParameter('/callisto/cognito_user_pool_id');
        CLIENT_ID = await getParameter('/callisto/cognito_client_id');

        cognitoClient = new CognitoIdentityProviderClient({ region: REGION });

        initialized = true;
    }
}

async function getParameter(name) {
    const command = new GetParameterCommand({ Name: name, WithDecryption: true });
    const response = await ssmClient.send(command);
    return response.Parameter.Value;
}

export const handler = async (event) => {
    await initializeCognitoConfig();

    const request = event.Records[0].cf.request;
    const headers = request.headers;

    // 1. 쿠키에서 토큰 추출
    const idToken = extractTokenFromCookie(headers, 'idToken');
    const accessToken = extractTokenFromCookie(headers, 'accessToken');
    const refreshToken = extractTokenFromCookie(headers, 'refreshToken');

    if (accessToken && isTokenValid(accessToken)) {
        return request; // 유효한 경우 그대로 전달
    }

    // 3. accessToken이 만료된 경우 refreshToken을 사용하여 재발급
    if (refreshToken) {
        try {
            const newTokens = await refreshTokensWithAwsSdk(refreshToken);
            setTokensInCookies(newTokens, headers);
            return request; // 새로운 토큰 설정 후 요청 전달
        } catch (error) {
            return errorResponse();
        }
    }

    return errorResponse(); // 토큰이 유효하지 않거나 재발급 실패 시
};

// AWS SDK를 통해 토큰 재발급
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

// 유틸리티 함수들
function extractTokenFromCookie(headers, tokenName) {
    const cookies = headers.cookie ? headers.cookie[0].value.split('; ') : [];
    const tokenCookie = cookies.find((cookie) => cookie.startsWith(`${tokenName}=`));
    return tokenCookie ? tokenCookie.split('=')[1] : null;
}

function isTokenValid(token) {
    try {
        const decoded = jwt.decode(token, { complete: true });
        return decoded && decoded.payload && decoded.payload.exp * 1000 > Date.now();
    } catch (error) {
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

function errorResponse() {
    return {
        status: '401',
        statusDescription: 'Forbidden',
        body: 'Unauthorized'
    };
}
