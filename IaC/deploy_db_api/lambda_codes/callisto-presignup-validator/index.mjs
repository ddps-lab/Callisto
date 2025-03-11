export const handler = async (event, context, callback) => {
  // Set the user pool autoConfirmUser flag after validating the email domain
  event.response.autoConfirmUser = false;

  const email = event.request.userAttributes.email;
  const emailDomain = email.split("@");
  const allowedDomains = ["hanyang.ac.kr", "kookmin.ac.kr"];

  if (!allowedDomains.includes(emailDomain[1])) {
    var error = new Error(
      "Only users with HYU or KMU email addresses can register.1"
    );
    callback(error, event);
  }

  // Return to Amazon Cognito
  callback(null, event);
};

// Ref. https://docs.aws.amazon.com/ko_kr/cognito/latest/developerguide/user-pool-lambda-pre-sign-up.html#aws-lambda-triggers-pre-registration-example
