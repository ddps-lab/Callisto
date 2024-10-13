import {
  CodeMismatchException,
  CognitoIdentityProviderClient,
  ConfirmSignUpCommand,
  InitiateAuthCommand,
  NotAuthorizedException,
  ResendConfirmationCodeCommand,
  SignUpCommand,
  UsernameExistsException,
  UserNotConfirmedException
} from '@aws-sdk/client-cognito-identity-provider';
import {
  COGNITO_CONFIRM_STATUS,
  COGNITO_SIGN_IN_STATUS,
  COGNITO_SIGN_UP_STATUS
} from '../../store/constant.js';

const cognitoClient = new CognitoIdentityProviderClient({
  region: import.meta.env.VITE_COGNITO_REGION
});

const ClientId = import.meta.env.VITE_COGNITO_CLIENT_ID;

export const cognitoSignIn = async (args) => {
  const { email, password } = args;
  const params = {
    AuthFlow: 'USER_PASSWORD_AUTH',
    ClientId,
    AuthParameters: {
      USERNAME: email,
      PASSWORD: password
    }
  };

  try {
    const command = new InitiateAuthCommand(params);
    const result = await cognitoClient.send(command);
    const { AuthenticationResult, ChallengeName, Session } = result;
    if (AuthenticationResult) {
      localStorage.setItem('refreshToken', AuthenticationResult.RefreshToken);
      return {
        status: COGNITO_SIGN_IN_STATUS.SUCCESS,
        idToken: AuthenticationResult.IdToken || '',
        accessToken: AuthenticationResult.AccessToken || ''
      };
    } else if (ChallengeName && Session) {
      return {
        status: COGNITO_SIGN_IN_STATUS.NEED_CHALLENGE,
        session: Session,
        challengeName: ChallengeName
      };
    }
  } catch (error) {
    if (error instanceof UserNotConfirmedException) {
      await cognitoClient.send(
        new ResendConfirmationCodeCommand({
          ClientId,
          Username: email
        })
      );
      return {
        status: COGNITO_SIGN_IN_STATUS.NEED_CONFIRM
      };
    } else if (error instanceof NotAuthorizedException) {
      return {
        status: COGNITO_SIGN_IN_STATUS.NOT_AUTHORIZED
      };
    }
    console.error(error);
    return {
      status: COGNITO_SIGN_IN_STATUS.ERROR
    };
  }
};

export const cognitoSignUp = async (args) => {
  const { email, password, familyName, firstname, nickname } = args;
  const params = {
    ClientId,
    Username: email,
    Password: password,
    UserAttributes: [
      {
        Name: 'email',
        Value: email
      },
      {
        Name: 'family_name',
        Value: familyName
      },
      {
        Name: 'name',
        Value: firstname
      },
      {
        Name: 'nickname',
        Value: nickname
      }
    ]
  };

  try {
    const command = new SignUpCommand(params);
    await cognitoClient.send(command);
    return {
      status: COGNITO_SIGN_UP_STATUS.SUCCESS
    };
  } catch (error) {
    if (error instanceof UsernameExistsException)
      return {
        status: COGNITO_SIGN_UP_STATUS.USERNAME_EXISTS
      };
    console.error(error);
    return {
      status: COGNITO_SIGN_UP_STATUS.ERROR
    };
  }
};

export const cognitoConfirmSignUp = async (email, code) => {
  const params = {
    ClientId,
    Username: email,
    ConfirmationCode: code
  };

  try {
    const command = new ConfirmSignUpCommand(params);
    await cognitoClient.send(command);
    return {
      status: COGNITO_CONFIRM_STATUS.SUCCESS
    };
  } catch (error) {
    if (error instanceof CodeMismatchException)
      return {
        status: COGNITO_CONFIRM_STATUS.CODE_MISS_MATCH
      };
    return {
      status: COGNITO_CONFIRM_STATUS.ERROR
    };
  }
};

export const cognitoRefreshAuth = async (refreshToken) => {
  const params = {
    AuthFlow: 'REFRESH_TOKEN_AUTH',
    ClientId,
    AuthParameters: {
      REFRESH_TOKEN: refreshToken
    }
  };

  const command = new InitiateAuthCommand(params);
  const result = await cognitoClient.send(command).catch(() => {
    location.href = '/';
  });

  const { AuthenticationResult } = result;
  if (AuthenticationResult) {
    return {
      status: COGNITO_SIGN_IN_STATUS.SUCCESS,
      idToken: AuthenticationResult.IdToken || '',
      accessToken: AuthenticationResult.AccessToken || ''
    };
  } else location.href = '/';
};
