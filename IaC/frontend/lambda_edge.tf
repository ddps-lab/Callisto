data "http" "cognito_jwks" {
  url = "https://cognito-idp.${var.region}.amazonaws.com/${var.callisto_cognito_user_pool_id}/.well-known/jwks.json"
}

locals {
  jwks_keys = jsondecode(data.http.cognito_jwks.response_body).keys
  hardcoded_jwks = jsonencode(local.jwks_keys)
}

resource "local_file" "jupyter_auth_lambda_index" {
  filename = "${path.module}/jupyter_auth/index_var.mjs"
  content = templatefile("${path.module}/jupyter_auth/index.mjs", {
    region = var.region
    user_pool_id = var.callisto_cognito_user_pool_id
    client_id = var.callisto_cognito_user_pool_client_id
    HARDCODED_JWK = local.hardcoded_jwks
  })

}

resource "local_file" "jupyter_refresh_token_lambda_index" {
  filename = "${path.module}/jupyter_refresh_token/index_var.mjs"
  content = templatefile("${path.module}/jupyter_refresh_token/index.mjs", {
    region = var.region
    user_pool_id = var.callisto_cognito_user_pool_id
    client_id = var.callisto_cognito_user_pool_client_id
  })

}
resource "null_resource" "compress_lambda_auth_code" {
  provisioner "local-exec" {
    command = <<-EOT
            cd ${path.module}/jupyter_auth && \
            npm install jsonwebtoken && \
            zip -r jupyter_auth_lambda.zip node_modules index_var.mjs
            EOT
  }

  depends_on = [ local_file.jupyter_auth_lambda_index ]
}

resource "null_resource" "compress_lambda_refresh_token_code" {
  provisioner "local-exec" {
    command = <<-EOT
            cd ${path.module}/jupyter_refresh_token && \
            zip -r jupyter_refresh_token_lambda.zip index_var.mjs
            EOT
  }

  depends_on = [ local_file.jupyter_refresh_token_lambda_index ]
}

resource "aws_iam_role" "jupyter_auth_lambda_role" {
  name = "callisto-jupyter-auth-lambda-role-${var.random_string}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = ["edgelambda.amazonaws.com", "lambda.amazonaws.com"]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "cognito_initiate_auth_policy" {
  name        = "callisto-cognito-initiate-auth-policy-${var.random_string}"
  description = "Policy to allow lambda to initiate auth flow with cognito"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cognito-idp:InitiateAuth",
          "cognito-idp:RespondToAuthChallenge"
        ],
        Resource = "arn:aws:cognito-idp:${var.region}:${data.aws_caller_identity.current.account_id}:userpool/${var.callisto_cognito_user_pool_id}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jupyter_auth_lambda_basic_policy" {
  role       = aws_iam_role.jupyter_auth_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "jupyter_auth_lambda_cognito_policy" {
  role       = aws_iam_role.jupyter_auth_lambda_role.name
  policy_arn = aws_iam_policy.cognito_initiate_auth_policy.arn
}

resource "aws_iam_role_policy_attachment" "jupyter_auth_lambda_ssm_parameter_policy" {
  role       = aws_iam_role.jupyter_auth_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_lambda_function" "jupyter_auth_lambda" {
  function_name = "callisto-jupyter-auth-lambda-${var.environment}-${var.random_string}"
  role          = aws_iam_role.jupyter_auth_lambda_role.arn
  handler       = "index_var.handler"
  runtime       = "nodejs20.x"
  filename      = "${path.module}/jupyter_auth/jupyter_auth_lambda.zip"
  publish       = true
  provider      = aws.virginia
  timeout       = 5
  depends_on    = [null_resource.compress_lambda_auth_code]
}

resource "aws_lambda_function" "jupyter_refresh_token_lambda" {
  function_name = "callisto-jupyter-refresh-token-lambda-${var.environment}-${var.random_string}"
  role          = aws_iam_role.jupyter_auth_lambda_role.arn
  handler       = "index_var.handler"
  runtime       = "nodejs20.x"
  filename      = "${path.module}/jupyter_refresh_token/jupyter_refresh_token_lambda.zip"
  publish       = true
  provider      = aws.virginia
  timeout       = 5
  depends_on    = [null_resource.compress_lambda_refresh_token_code]
}
