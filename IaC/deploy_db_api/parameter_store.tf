resource "aws_ssm_parameter" "cognito_client_id" {
  name  = "/callisto/cognito_client_id"
  type  = "String"
  value = aws_cognito_user_pool_client.callisto_user_pool_client.id
  provider = aws.virginia
}

resource "aws_ssm_parameter" "cognito_user_pool_id" {
  name  = "/callisto/cognito_user_pool_id"
  type  = "String"
  value = aws_cognito_user_pool.callisto_user_pool.id
  provider = aws.virginia
}

resource "aws_ssm_parameter" "cognito_region" {
  name  = "/callisto/cognito_region"
  type  = "String"
  value = var.region
  provider = aws.virginia
}
