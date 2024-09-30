resource "aws_apigatewayv2_api" "callisto_db_api" {
  name = "Callisto DB REST-API-${var.environment}-${var.random_hex}"
  protocol_type = "HTTP"
  cors_configuration {
    allow_methods = ["*"]
    allow_origins = ["*"]
    allow_headers = ["*"]
  }
}

### lambda permissions
resource "aws_lambda_permission" "callisto_ddb_jupyter_api_permission" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.callisto-ddb-jupyter-api.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.callisto_db_api.execution_arn}/*/*"
}


resource "aws_lambda_permission" "callisto_ddb_users_api_permission" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.callisto-ddb-users-api.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.callisto_db_api.execution_arn}/*/*"
}

### integrations
resource "aws_apigatewayv2_integration" "jupyter_integration" {
    api_id = aws_apigatewayv2_api.callisto_db_api.id
    integration_type = "AWS_PROXY"
    integration_method = "POST"
    integration_uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.callisto-ddb-jupyter-api.arn}/invocations"
    payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "users_integration" {
    api_id = aws_apigatewayv2_api.callisto_db_api.id
    integration_type = "AWS_PROXY"
    integration_method = "POST"
    integration_uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.callisto-ddb-users-api.arn}/invocations"
    payload_format_version = "2.0"
}

### routes
# /jupyter
resource "aws_apigatewayv2_route" "jupyter_post_route" {
  api_id = aws_apigatewayv2_api.callisto_db_api.id
  route_key = "POST /jupyter"
  target = "integrations/${aws_apigatewayv2_integration.jupyter_integration.id}"
}

resource "aws_apigatewayv2_route" "jupyter_get_route" {
  api_id = aws_apigatewayv2_api.callisto_db_api.id
  route_key = "GET /jupyter"
  target = "integrations/${aws_apigatewayv2_integration.jupyter_integration.id}"
}

resource "aws_apigatewayv2_route" "jupyter_put_id_route" {
  api_id = aws_apigatewayv2_api.callisto_db_api.id
  route_key = "PUT /jupyter/{id}"
  target = "integrations/${aws_apigatewayv2_integration.jupyter_integration.id}"
}

resource "aws_apigatewayv2_route" "jupyter_get_id_route" {
  api_id = aws_apigatewayv2_api.callisto_db_api.id
  route_key = "GET /jupyter/{id}"
  target = "integrations/${aws_apigatewayv2_integration.jupyter_integration.id}"
}

resource "aws_apigatewayv2_route" "jupyter_delete_id_route" {
  api_id = aws_apigatewayv2_api.callisto_db_api.id
  route_key = "DELETE /jupyter/{id}"
  target = "integrations/${aws_apigatewayv2_integration.jupyter_integration.id}"
}

# /users
resource "aws_apigatewayv2_route" "users_post_route" {
  api_id = aws_apigatewayv2_api.callisto_db_api.id
  route_key = "POST /users"
  target = "integrations/${aws_apigatewayv2_integration.users_integration.id}"
}

resource "aws_apigatewayv2_route" "users_get_route" {
  api_id = aws_apigatewayv2_api.callisto_db_api.id
  route_key = "GET /users"
  target = "integrations/${aws_apigatewayv2_integration.users_integration.id}"
}

resource "aws_apigatewayv2_route" "users_put_id_route" {
  api_id = aws_apigatewayv2_api.callisto_db_api.id
  route_key = "PUT /users/{id}"
  target = "integrations/${aws_apigatewayv2_integration.users_integration.id}"
}

resource "aws_apigatewayv2_route" "users_get_id_route" {
  api_id = aws_apigatewayv2_api.callisto_db_api.id
  route_key = "GET /users/{id}"
  target = "integrations/${aws_apigatewayv2_integration.users_integration.id}"
}

resource "aws_apigatewayv2_route" "users_delete_id_route" {
  api_id = aws_apigatewayv2_api.callisto_db_api.id
  route_key = "DELETE /users/{id}"
  target = "integrations/${aws_apigatewayv2_integration.users_integration.id}"
}

### stage deploy
resource "aws_apigatewayv2_stage" "apigtw_stage" {
  api_id = aws_apigatewayv2_api.callisto_db_api.id
  name = "callisto-api-${var.environment}-${var.random_hex}"
  auto_deploy = true
}

### DNS mapping
resource "aws_acm_certificate" "certificate" {
  domain_name       = "db.api.${var.route53_domain}"
  validation_method = "DNS"
}

resource "aws_route53_record" "validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.route53_zone.zone_id
}

resource "aws_acm_certificate_validation" "certificate_validation" {
  certificate_arn = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.validation_record : record.fqdn]
}

resource "aws_apigatewayv2_domain_name" "api_domain_name" {
  domain_name = "db.api.${var.route53_domain}"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.certificate.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  depends_on = [ aws_acm_certificate_validation.certificate_validation ]
}

resource "aws_route53_record" "route53_record" {
  name    = aws_apigatewayv2_domain_name.api_domain_name.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.route53_zone.zone_id

  alias {
    name                   = aws_apigatewayv2_domain_name.api_domain_name.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_domain_name.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_apigatewayv2_api_mapping" "api_mapping" {
  api_id = aws_apigatewayv2_api.callisto_db_api.id
  domain_name = aws_apigatewayv2_domain_name.api_domain_name.id
  stage = aws_apigatewayv2_stage.apigtw_stage.id
}