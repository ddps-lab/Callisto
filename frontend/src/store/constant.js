export const PASSWORD_REGEX =
  /^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[ \^$*.\[\]{}()?\-"!@#%&/\\,><':;|_~`+=]).{8,}$/;

export const COGNITO_SIGN_IN_STATUS = {
  SUCCESS: 0,
  NEED_CHALLENGE: 1,
  NEED_CONFIRM: 2,
  NOT_AUTHORIZED: 3,
  ERROR: -1
};

export const COGNITO_CONFIRM_STATUS = {
  SUCCESS: 0,
  CODE_MISS_MATCH: 1,
  ERROR: -1
};

export const COGNITO_SIGN_UP_STATUS = {
  SUCCESS: 0,
  USERNAME_EXISTS: 1,
  ERROR: -1
};
