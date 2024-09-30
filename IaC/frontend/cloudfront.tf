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

  zone_id = data.aws_route53_zone.route53_zone.zone_id
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

resource "aws_cloudfront_cache_policy" "example_cache_policy" {
  name    = "example-cache-policy"
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
      header_behavior = "whitelist"
      headers {
        items = ["Origin"]
      }
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "example_origin_request_policy" {
  name    = "example-origin-request-policy"
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

resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name = aws_s3_bucket.callisto_web_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.callisto_web_bucket.id}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
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
    cache_policy_id            = aws_cloudfront_cache_policy.example_cache_policy.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.example_origin_request_policy.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.cors_policy.id
    viewer_protocol_policy     = "redirect-to-https"
    min_ttl                    = 0
    default_ttl                = 3600
    max_ttl                    = 86400
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
  name = "AllowAllCORSHeadersPolicy"

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
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = ""
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
