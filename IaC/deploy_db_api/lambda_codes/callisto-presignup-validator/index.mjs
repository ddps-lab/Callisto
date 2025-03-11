export const handler = async (event, context, callback) => {
  // Set the user pool autoConfirmUser flag after validating the email domain
  event.response.autoConfirmUser = false;

  const email = event.request.userAttributes.email;
  const emailDomain = email.split("@")[1];
  const allowedDomains = process.env.ALLOWED_DOMAINS
    ? process.env.ALLOWED_DOMAINS.split(",").map((domain) => domain.trim())
    : [];

  if (!allowedDomains.includes(emailDomain)) {
    var error = new Error(
      "Only users with approved email addresses can register."
    );
    callback(error, event);
  }

  // Return to Amazon Cognito
  callback(null, event);
};

// Ref. https://docs.aws.amazon.com/ko_kr/cognito/latest/developerguide/user-pool-lambda-pre-sign-up.html#aws-lambda-triggers-pre-registration-example
