output "api_endpoint_url" {
  value = aws_apigatewayv2_stage.apigtw_stage.invoke_url
}

output "api_endpoint_domain_url" {
  value = aws_apigatewayv2_domain_name.api_domain_name.domain_name
}

output "callisto-jupyter_table_name" {
  value = aws_dynamodb_table.callisto-jupyter.name
}

output "callisto_cognito_user_pool_id" {
  value = aws_cognito_user_pool.callisto_user_pool.id
}

output "callisto_cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.callisto_user_pool_client.id
}