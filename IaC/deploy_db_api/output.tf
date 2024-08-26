output "api_endpoint_url" {
  value = aws_apigatewayv2_stage.apigtw_stage.invoke_url
}

output "api_endpoint_domain_url" {
  value = aws_apigatewayv2_domain_name.api_domain_name.domain_name
}