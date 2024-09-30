resource "aws_s3_bucket" "callisto_web_bucket" {
  bucket        = "callisto-web-${var.environment}-${var.random_string}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "callisto-s3-web-bucket-public-conf" {
  bucket = aws_s3_bucket.callisto_web_bucket.bucket

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "callisto-s3-web-bucket-policy" {
  bucket = aws_s3_bucket.callisto_web_bucket.bucket
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCloudFrontReadOnly"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.callisto_web_bucket.id}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.callisto-s3-web-bucket-public-conf]
}
