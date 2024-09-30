# output "api_endpoint_domain_url" {
#   value = aws_api_gateway_domain_name.api_domain_name.domain_name
# }

output "callisto-jupyter_table_name" {
  value = aws_dynamodb_table.callisto-jupyter.name
}

output "callisto_cognito_user_pool_id" {
  value = aws_cognito_user_pool.callisto_user_pool.id
}

output "callisto_cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.callisto_user_pool_client.id
}

output "api_gateway_execution_arn" {
  value = aws_api_gateway_deployment.callisto_db_api_deployment.execution_arn
}

output "api_gateway_id" {
  value = aws_api_gateway_rest_api.callisto_db_api.id
}