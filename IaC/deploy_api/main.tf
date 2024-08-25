resource "aws_apigatewayv2_api" "callisto_api" {
  name = "Callisto REST-API-${random_id.random_string.hex}"
  protocol_type = "HTTP"
  cors_configuration {
    allow_methods = ["*"]
    allow_origins = ["*"]
    allow_headers = ["*"]
  }
}

### lambda permissions
resource "aws_lambda_permission" "callisto_jupyter_controller_api_permission" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = var.jupyter_controller_function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.callisto_api.execution_arn}/*/*"
}

### integrations
resource "aws_apigatewayv2_integration" "jupyter_controller_integration" {
    api_id = aws_apigatewayv2_api.callisto_api.id
    integration_type = "AWS_PROXY"
    integration_method = "POST"
    integration_uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.jupyter_controller_function_arn}/invocations"
    payload_format_version = "2.0"
}

### routes
# /jupyter_controller
resource "aws_apigatewayv2_route" "jupyter_controller_post_route" {
  api_id = aws_apigatewayv2_api.callisto_api.id
  route_key = "POST /jupyter_controller"
  target = "integrations/${aws_apigatewayv2_integration.jupyter_controller_integration.id}"
}

### stage deploy
resource "aws_apigatewayv2_stage" "apigtw_stage" {
  api_id = aws_apigatewayv2_api.callisto_api.id
  name = "callisto-api-dev"
  auto_deploy = true
}


### DNS mapping
resource "aws_acm_certificate" "certificate" {
  domain_name       = "api.${var.route53_domain}"
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
  domain_name = "api.${var.route53_domain}"

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
  api_id = aws_apigatewayv2_api.callisto_api.id
  domain_name = aws_apigatewayv2_domain_name.api_domain_name.id
  stage = aws_apigatewayv2_stage.apigtw_stage.id
}