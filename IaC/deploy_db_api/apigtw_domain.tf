
### DNS mapping
resource "aws_acm_certificate" "certificate" {
  domain_name       = "db.api.${var.route53_domain}"
  validation_method = "DNS"
  provider = aws.virginia
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
  provider = aws.virginia
}

resource "aws_api_gateway_domain_name" "api_domain_name" {
  domain_name     = "db.api.${var.route53_domain}"
  certificate_arn = aws_acm_certificate_validation.certificate_validation.certificate_arn
}

resource "aws_route53_record" "route53_record" {
  name    = aws_api_gateway_domain_name.api_domain_name.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.route53_zone.zone_id

  alias {
    name                   = aws_api_gateway_domain_name.api_domain_name.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api_domain_name.cloudfront_zone_id
    evaluate_target_health = false
  }
}

resource "aws_api_gateway_base_path_mapping" "api_base_path_mapping" {
  domain_name = aws_api_gateway_domain_name.api_domain_name.domain_name
  api_id      = aws_api_gateway_rest_api.callisto_db_api.id
  stage_name  = aws_api_gateway_deployment.callisto_db_api_deployment.stage_name
}
