resource "aws_lambda_function" "callisto-ddb-jupyter-api" {
  function_name = "callisto-ddb-jupyter-api-${var.environment}-${var.random_string}"
  package_type  = "Image"
  architectures = ["x86_64"]
  image_uri     = "${var.container_registry}/${var.jupyter_api_container_repository}:${var.jupyter_api_image_tag}"
  role          = aws_iam_role.lambda_api_role.arn
  memory_size   = 128
  timeout       = 60

  environment {
    variables = {
      REGION            = var.region
      TABLE_NAME        = var.jupyter_ddb_table_name
      TABLE_ARN         = aws_dynamodb_table.callisto-jupyter.arn
      EKS_CLUSTER_NAME  = var.eks_cluster_name
      ROUTE53_DOMAIN    = var.route53_domain
      ECR_URI           = var.container_registry
      OIDC_PROVIDER     = var.oidc_provider
      OIDC_PROVIDER_ARN = var.oidc_provider_arn
    }
  }
}

resource "aws_iam_role" "callisto_cognito_presignup_validator_lambda_role" {
  name = "callisto-cognito-presignup-validator-lambda-role-${var.random_string}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = ["lambda.amazonaws.com"]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "callisto_cognito_presignup_validator_lambda_basic_policy" {
  role       = aws_iam_role.callisto_cognito_presignup_validator_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "local_file" "callisto_cognito_presignup_validator_lambda_index" {
  filename = "${path.module}/lambda_codes/callisto-presignup-validator/index.zip"
  content = file("${path.module}/lambda_codes/callisto-presignup-validator/index.mjs")
}

resource "aws_lambda_function" "callisto_cognito_presignup_validator_lambda" {
  function_name = "callisto-cognito-presignup-validator-lambda-${var.environment}-${var.random_string}"
  handler       = "index.handler"
  runtime       = "nodejs22.x"
  role          = aws_iam_role.callisto_cognito_presignup_validator_lambda_role.arn
  filename      = "${path.module}/lambda_codes/callisto-presignup-validator/index.zip"
}

resource "aws_lambda_permission" "callisto_cognito_presignup_validator_lambda_permission" {
  statement_id = "AllowExecutionFromCognito"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.callisto_cognito_presignup_validator_lambda.function_name
  principal = "cognito-idp.amazonaws.com"
}