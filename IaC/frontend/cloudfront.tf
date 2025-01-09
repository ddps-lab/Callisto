resource "aws_acm_certificate" "web_cert" {
  provider          = aws.virginia
  domain_name       = var.route53_domain
  validation_method = "DNS"

  subject_alternative_names = ["${var.route53_domain}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  provider = aws.virginia

  for_each = {
    for dvo in aws_acm_certificate.web_cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = var.route53_data.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.web_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for accessing ${aws_s3_bucket.callisto_web_bucket.bucket}"
}

resource "aws_cloudfront_cache_policy" "origin_cache_policy" {
  name    = "origin-cache-policy-${var.random_string}"
  comment = "Cache policy for example CloudFront distribution"

  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip = true
    cookies_config {
      cookie_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "origin_request_policy" {
  name    = "origin-request-policy-${var.random_string}"
  comment = "Origin Request policy for example CloudFront distribution"
  cookies_config {
    cookie_behavior = "none"
  }

  query_strings_config {
    query_string_behavior = "none"
  }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]
    }
  }
}

resource "aws_cloudfront_cache_policy" "cache_disabled_policy" {
  name    = "caching-disabled-${var.random_string}"
  comment = "Cache policy for cache disable"

  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "api_gateway_request_policy" {
  name = "api-gateway-origin-request-policy-${var.random_string}"

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Id-Token", "Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers", "Content-Type"]
    }
  }

  query_strings_config {
    query_string_behavior = "all"
  }

  cookies_config {
    cookie_behavior = "none"
  }
}

resource "aws_cloudfront_origin_request_policy" "nlb_request_policy" {
  name = "nlb-origin-request-policy-${var.random_string}"

  headers_config {
    header_behavior = "allViewer"
  }

  query_strings_config {
    query_string_behavior = "all"
  }

  cookies_config {
    cookie_behavior = "all"
  }
}

resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name = aws_s3_bucket.callisto_web_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.callisto_web_bucket.id}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = "${var.api_gateway_id}.execute-api.${var.region}.amazonaws.com"
    origin_id   = "APIGateway-Origin"
    origin_path = "/${var.environment}"

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin {
    domain_name = data.local_file.nlb_dns_name.content
    origin_id   = "NLB-Origin"

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [var.route53_domain]

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-${aws_s3_bucket.callisto_web_bucket.id}"
    cache_policy_id            = aws_cloudfront_cache_policy.origin_cache_policy.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.origin_request_policy.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.cors_policy.id
    viewer_protocol_policy     = "redirect-to-https"
    min_ttl                    = 0
    default_ttl                = 3600
    max_ttl                    = 86400
  }

  ordered_cache_behavior {
    path_pattern           = "/api/jupyter-access/*"
    target_origin_id       = "NLB-Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    default_ttl = 0
    max_ttl     = 0
    min_ttl     = 0

    cache_policy_id          = aws_cloudfront_cache_policy.cache_disabled_policy.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.nlb_request_policy.id

    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = aws_lambda_function.jupyter_auth_lambda.qualified_arn
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "APIGateway-Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    default_ttl = 0
    max_ttl     = 0
    min_ttl     = 0

    cache_policy_id          = aws_cloudfront_cache_policy.cache_disabled_policy.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.api_gateway_request_policy.id
  }

  custom_error_response {
    error_code            = 403
    response_page_path    = "/"
    response_code         = 200
    error_caching_min_ttl = 300
  }

  price_class = "PriceClass_All"

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "S3-to-CloudFront-Distribution"
  }

  depends_on = [aws_acm_certificate_validation.cert_validation]
}

resource "aws_cloudfront_response_headers_policy" "cors_policy" {
  name = "AllowAllCORSHeadersPolicy-${var.random_string}"

  cors_config {
    access_control_allow_credentials = false
    access_control_allow_headers {
      items = ["*"]
    }
    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    }
    access_control_allow_origins {
      items = ["*"]
    }
    access_control_expose_headers {
      items = ["*"]
    }
    access_control_max_age_sec = 3000
    origin_override            = true
  }
}


resource "aws_route53_record" "root" {
  zone_id = var.route53_data.zone_id
  name    = ""
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
