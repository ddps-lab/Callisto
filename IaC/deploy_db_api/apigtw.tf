resource "aws_apigatewayv2_api" "callisto_db_api" {
  name          = "Callisto DB REST-API-${var.environment}-${var.random_hex}"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_headers = ["id-token", "Content-Type"]
    allow_methods = ["OPTIONS", "GET", "POST", "PUT", "DELETE", "PATCH"]
    max_age       = 3600
  }
}

### lambda permissions
resource "aws_lambda_permission" "callisto_ddb_jupyter_api_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.callisto-ddb-jupyter-api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.callisto_db_api.execution_arn}/*/*"
}

### integrations
resource "aws_apigatewayv2_integration" "jupyter_integration" {
  api_id                 = aws_apigatewayv2_api.callisto_db_api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.callisto-ddb-jupyter-api.arn}/invocations"
  payload_format_version = "2.0"
}

### authorizer (cognito)
resource "aws_apigatewayv2_authorizer" "callisto_cognito_authorizer" {
  api_id           = aws_apigatewayv2_api.callisto_db_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.id-token"]
  name             = "callisto-cognito-authorizer"

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.callisto_user_pool_client.id]
    issuer   = aws_cognito_user_pool.callisto_user_pool.endpoint
  }
}

### routes
# /jupyter
resource "aws_apigatewayv2_route" "jupyter_route" {
  api_id             = aws_apigatewayv2_api.callisto_db_api.id
  route_key          = "ANY /jupyter"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.callisto_cognito_authorizer.id
  target             = "integrations/${aws_apigatewayv2_integration.jupyter_integration.id}"
}

resource "aws_apigatewayv2_route" "jupyter_uid_route" {
  api_id             = aws_apigatewayv2_api.callisto_db_api.id
  route_key          = "ANY /jupyter/{uid}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.callisto_cognito_authorizer.id
  target             = "integrations/${aws_apigatewayv2_integration.jupyter_integration.id}"
}

### stage deploy
resource "aws_apigatewayv2_stage" "apigtw_stage" {
  api_id      = aws_apigatewayv2_api.callisto_db_api.id
  name        = "callisto-api-${var.environment}-${var.random_hex}"
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
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.validation_record : record.fqdn]
}

resource "aws_apigatewayv2_domain_name" "api_domain_name" {
  domain_name = "db.api.${var.route53_domain}"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.certificate.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  depends_on = [aws_acm_certificate_validation.certificate_validation]
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
  api_id      = aws_apigatewayv2_api.callisto_db_api.id
  domain_name = aws_apigatewayv2_domain_name.api_domain_name.id
  stage       = aws_apigatewayv2_stage.apigtw_stage.id
}
