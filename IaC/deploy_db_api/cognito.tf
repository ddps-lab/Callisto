resource "aws_cognito_user_pool" "callisto_user_pool" {
  name = "callisto-user-pool-${var.environment}-${var.random_hex}"

  alias_attributes  = ["email"]
  mfa_configuration = "OFF"

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
}

resource "aws_cognito_user_pool_client" "callisto_user_pool_client" {
  user_pool_id = aws_cognito_user_pool.callisto_user_pool.id
  name = "callisto_user_pool_client-${var.environment}-${lower(var.random_hex)}"

  generate_secret = false

  allowed_oauth_flows = [ "code", "implicit", "client_credentials" ]
  allowed_oauth_flows_user_pool_client = true
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"
}

resource "aws_cognito_user_pool_domain" "callisto_user_pool_domain" {
  domain = "callisto_user_pool_domain-${var.environment}-${lower(var.random_hex)}"
  user_pool_id = aws_cognito_user_pool.callisto_user_pool.id
}


