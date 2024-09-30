output "s3_website_url" {
 value = aws_s3_bucket_website_configuration.callisto-s3-web-bucket-web-conf.website_domain
}

output "website_bucket_name" {
  value = aws_s3_bucket.callisto_web_bucket.bucket
}
