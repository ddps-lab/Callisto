resource "aws_cognito_user_pool" "callisto_user_pool" {
  name                = "callisto-user-pool-${var.environment}-${var.random_string}"
  username_attributes = ["email"]
  mfa_configuration   = "OFF"
  auto_verified_attributes = ["email"]
  
  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
  }

  schema {
    attribute_data_type = "String"
    name                = "family_name"
    required            = true
  }

  schema {
    attribute_data_type = "String"
    name                = "name"
    required            = true
  }

  schema {
    attribute_data_type = "String"
    name                = "nickname"
    required            = true
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  verification_message_template {
    email_message = "Your verification code is {####}."
    email_subject = "[Callisto] Verify your email address"
  }

  lambda_config {
    pre_sign_up = aws_lambda_function.callisto_cognito_presignup_validator_lambda.arn
  }
}

resource "aws_cognito_user_pool_client" "callisto_user_pool_client" {
  user_pool_id = aws_cognito_user_pool.callisto_user_pool.id
  name         = "callisto_user_pool_client-${var.environment}-${lower(var.random_string)}"

  generate_secret = false

  # allowed_oauth_flows = [ "code", "implicit" ]
  # allowed_oauth_scopes = [ "email", "openid", "profile", "aws.cognito.signin.user.admin" ]
  # allowed_oauth_flows_user_pool_client = true
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"
}

resource "aws_cognito_user_pool_domain" "callisto_user_pool_domain" {
  domain       = "callisto-user-pool-domain-${var.environment}-${lower(var.random_string)}"
  user_pool_id = aws_cognito_user_pool.callisto_user_pool.id
}
