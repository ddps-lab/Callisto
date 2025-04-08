// import { SSMClient, GetParameterCommand } from '@aws-sdk/client-ssm';
import { CognitoIdentityProviderClient } from '@aws-sdk/client-cognito-identity-provider';
import jwt from 'jsonwebtoken';
import axios from 'axios';
import jwkToPem from 'jwk-to-pem';

// let ssmClient;
let cognitoClient;

let pemCache = {};
let lastUpdated = 0; // Initialize lastUpdated
const CACHE_TTL = 3600 * 1000; // Example: 1 hour in milliseconds

const REGION = "${region}"
const USER_POOL_ID = "${user_pool_id}"
// const CLIENT_ID = "${client_id}" // Keep CLIENT_ID if needed elsewhere, or remove if truly unused
const JWK_URL = `https://cognito-idp.$${REGION}.amazonaws.com/$${USER_POOL_ID}/.well-known/jwks.json`

// IMPORTANT: Replace ${HARDCODED_JWK} with an actual valid JSON array during deployment
// Example format: const HARDCODED_JWK = [{ "kid": "abc...", "alg": "RS256", ... }, ...];
// The current line will cause a syntax error if not replaced.
const HARDCODED_JWK = ${HARDCODED_JWK}; 

if (Array.isArray(HARDCODED_JWK)) {
    HARDCODED_JWK.forEach((jwk) => {
        try {
            pemCache[jwk.kid] = jwkToPem(jwk);
        } catch (e) {
            console.error(`Error converting hardcoded JWK with kid $${jwk.kid}:`, e);
        }
    });
} else {
    console.error('HARDCODED_JWK is not a valid array. JWK initialization skipped.');
}

// async function initializeCognitoConfig() {
//     if (!cognitoClient) {
//         // Cognito client might still be needed if other Cognito actions are performed
//         // If not, this initialization and the import can be removed.
//         cognitoClient = new CognitoIdentityProviderClient({ region: REGION });
//     }
// }

async function updateJwksIfNeeded() {
    // Check if cache is expired
    if (Date.now() - lastUpdated < CACHE_TTL) {
        console.log("JWK cache is still valid.");
        return;
    }

    try {
        console.log("Fetching new JWKs from Cognito...");
        const response = await axios.get(JWK_URL);
        const jwks = response.data.keys;

        // Reset cache and populate with new keys
        const newPemCache = {};
        jwks.forEach((jwk) => {
            try {
                newPemCache[jwk.kid] = jwkToPem(jwk);
            } catch(e) {
                console.error(`Error converting fetched JWK with kid $${jwk.kid}:`, e);
            }
        });
        pemCache = newPemCache; // Atomically update the cache

        lastUpdated = Date.now();
        console.log("JWKs updated successfully.");
    } catch (error) {
        console.error("Failed to fetch or process JWKs:", error);
        // Keep using the potentially stale cache or hardcoded keys
    }
}

export const handler = async (event) => {
    // Initialize any necessary configs (Cognito client might be optional now)
    // await initializeCognitoConfig(); 
    
    // Ensure JWKs are reasonably fresh before validation
    // await updateJwksIfNeeded(); 

    const request = event.Records[0].cf.request;
    const headers = request.headers;

    const uuid = extractUuidFromPath(request.uri);
    if (!uuid) {
        console.log("Could not extract UUID from path:", request.uri);
        // Decide if this is an error or if some paths don't need auth
        // return errorResponse("Invalid request path"); 
    }

    const idToken = extractTokenFromCookie(headers, 'idToken');
    // const accessToken = extractTokenFromCookie(headers, 'accessToken'); // accessToken usually not validated here
    const refreshToken = extractTokenFromCookie(headers, 'refreshToken');

    if (!idToken) {
        console.log("idToken cookie missing.");
        return errorResponse("Missing credentials");
    }

    const tokenValidationResult = await isTokenValid(idToken, uuid);

    if (tokenValidationResult === true) {
        // Token is valid, let the request proceed
        console.log("Token is valid.");
        return request;
    } else if (tokenValidationResult === "TokenExpired" && refreshToken) {
        // Token expired, but refresh token exists. Signal the Viewer Response function.
        console.log("Token expired, refresh token found. Setting refresh signal header.");
        // Add the custom header to signal the response function
        // Header names are lowercased in the headers object
        headers['x-needs-token-refresh'] = [{ key: 'X-Needs-Token-Refresh', value: 'true' }];
        // Allow the request to proceed with the added header
        return request;
    } else {
        // Token is invalid (UUID mismatch, bad signature, expired with no refresh token, etc.)
        console.log(`Invalid token or missing refresh token. Reason: $${tokenValidationResult}`);
        return errorResponse(tokenValidationResult === "TokenUUIDMismatch" ? "Token UUID mismatch" : "Invalid or expired token");
    }
    // Note: The original code had a fallback 'return request' here, which seemed incorrect.
    // All paths should lead to returning the request (potentially modified) or an error response.
};

function extractUuidFromPath(path) {
    // Example: /api/jupyter-access/uuid-part-12345/more/path
    // Adjust regex if UUID format or path structure is different
    const match = path.match(/\/api\/jupyter-access\/([a-f0-9-]{36})/);
    return match ? match[1] : null;
}

function extractTokenFromCookie(headers, tokenName) {
    const cookieHeader = headers.cookie;
    if (!cookieHeader || cookieHeader.length === 0) {
        return null;
    }
    const cookieString = cookieHeader.map(h => h.value).join('; ');
    const cookies = cookieString.split('; ');
    const tokenCookie = cookies.find((cookie) => cookie.trim().startsWith(`$${tokenName}=`));
    return tokenCookie ? tokenCookie.split('=')[1] : null;
}

async function isTokenValid(token, uuid) {
    let decoded;
    try {
        decoded = jwt.decode(token, { complete: true });
        if (!decoded || !decoded.header || !decoded.header.kid) {
            console.error('Invalid token structure or missing kid');
            return "InvalidTokenStructure";
        }
    } catch (error) {
        console.error('Error decoding token:', error);
        return "InvalidTokenStructure";
    }
    
    const kid = decoded.header.kid;
    let publicKey = pemCache[kid];

    if (!publicKey) {
        console.log(`Public key for kid $${kid} not in cache. Attempting JWK update.`);
        await updateJwksIfNeeded(); // Attempt to refresh JWKs if kid not found
        publicKey = pemCache[kid]; // Try again after potential update

        if (!publicKey) {
            console.error(`Public key for kid $${kid} still not found after update attempt.`);
            // Depending on policy, could try one hard refresh or fail
            return 'PublicKeyNotFound'; // Specific error
        }
    }

    try {
        const verifiedToken = jwt.verify(token, publicKey, { algorithms: ['RS256'] });
        console.log("Token signature verified.");

        // Check UUID match only if profile is not admin
        if (verifiedToken.profile !== 'admin' && verifiedToken.sub !== uuid) {
            console.log(`Token UUID mismatch: token sub ($${verifiedToken.sub}) vs path uuid ($${uuid}).`);
            return "TokenUUIDMismatch";
        }
        console.log("Token UUID check passed (or user is admin).");
        return true; // Token is valid
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            console.log("Token expired.");
            return "TokenExpired";
        } else if (error.name === 'JsonWebTokenError') {
            console.error("Token verification failed (JsonWebTokenError):", error.message);
            return "VerificationError"; 
        } else {
            console.error("Unknown error during token verification:", error);
            return "VerificationError";
        }
    }
}

function errorResponse(message) {
    console.log(`Returning 401 Error Response: $${message}`);
    return {
        status: '401',
        statusDescription: 'Unauthorized',
        headers: {
            // Optional: Add headers like WWW-Authenticate if needed
            'content-type': [{ key: 'Content-Type', value: 'text/plain' }]
        },
        body: message || 'Unauthorized',
    };
}