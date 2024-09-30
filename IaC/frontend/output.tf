output "website_url" {
 value = aws_cloudfront_distribution.distribution.domain_name
}

output "website_bucket_name" {
  value = aws_s3_bucket.callisto_web_bucket.bucket
}
