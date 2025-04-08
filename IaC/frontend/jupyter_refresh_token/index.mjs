import { CognitoIdentityProviderClient, AdminInitiateAuthCommand } from '@aws-sdk/client-cognito-identity-provider';

let cognitoClient;

const REGION = "${region}"
const USER_POOL_ID = "${user_pool_id}"
const CLIENT_ID = "${client_id}"

async function initializeCognitoConfig() {
    if (!cognitoClient) {
        cognitoClient = new CognitoIdentityProviderClient({ region: REGION });
    }
}

export const handler = async (event) => {
    await initializeCognitoConfig();

    const cf = event.Records[0].cf;
    const request = cf.request;
    const response = cf.response;
    const requestHeaders = request.headers;
    const responseHeaders = response.headers;

    const needsRefreshHeader = requestHeaders['x-needs-token-refresh'];

    if (needsRefreshHeader && needsRefreshHeader[0]?.value === 'true') {
        console.log('Token refresh triggered by x-needs-token-refresh header.');
        const refreshToken = extractTokenFromCookie(requestHeaders, 'refreshToken');

        if (refreshToken) {
            try {
                console.log('Attempting to refresh tokens...');
                const newTokens = await refreshTokensWithAwsSdk(refreshToken);
                console.log('Tokens refreshed successfully.');
                setTokensInCookies(newTokens, responseHeaders);
                console.log('Set-Cookie headers added to the response.');

                if (responseHeaders['x-needs-token-refresh']) {
                    delete responseHeaders['x-needs-token-refresh'];
                }

            } catch (error) {
                console.error("Failed to refresh token:", error);
            }
        } else {
            console.log('X-Needs-Token-Refresh header present, but no refreshToken found in request cookies.');
        }
    } else {
        // Log if the header wasn't found or had the wrong value, for debugging.
        // console.log('No token refresh needed or header not set correctly.');
    }

    return response;
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
    console.log(`Refreshing token for UserPool: $${USER_POOL_ID}, Client: $${CLIENT_ID}`);
    const command = new AdminInitiateAuthCommand(params);
    const cognitoResponse = await cognitoClient.send(command);

    if (cognitoResponse.AuthenticationResult) {
        console.log('Cognito refresh successful.');
        return {
            id_token: cognitoResponse.AuthenticationResult.IdToken,
            access_token: cognitoResponse.AuthenticationResult.AccessToken,
        };
    } else {
        console.error('Cognito refresh failed, AuthenticationResult missing.');
        throw new Error('Token refresh failed, AuthenticationResult missing.');
    }
}

function extractTokenFromCookie(headers, tokenName) {
    const cookieHeader = headers.cookie;
    if (!cookieHeader || cookieHeader.length === 0) {
        console.log(`Cookie header not found when trying to extract $${tokenName}.`);
        return null;
    }
    const cookieString = cookieHeader.map(h => h.value).join('; ');
    const cookies = cookieString.split('; ');
    const tokenCookie = cookies.find((cookie) => cookie.trim().startsWith(`$${tokenName}=`));

    if (tokenCookie) {
        return tokenCookie.split('=')[1];
    } else {
        console.log(`Cookie '$${tokenName}' not found.`);
        return null;
    }
}

function setTokensInCookies(tokens, headers) {
    const newCookies = [
        { key: 'Set-Cookie', value: `idToken=$${tokens.id_token}; Path=/; Secure; HttpOnly; SameSite=Lax` },
        { key: 'Set-Cookie', value: `accessToken=$${tokens.access_token}; Path=/; Secure; HttpOnly; SameSite=Lax` }
    ];
    console.log(`Setting cookies: idToken=$${tokens.id_token ? 'present' : 'missing'}, accessToken=$${tokens.access_token ? 'present' : 'missing'}`);

    headers['set-cookie'] = headers['set-cookie'] ? [...headers['set-cookie'], ...newCookies] : newCookies;
}