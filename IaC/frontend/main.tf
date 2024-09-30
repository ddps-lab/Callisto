resource "aws_s3_bucket" "callisto_web_bucket" {
    bucket = "callisto-web-${var.environment}-${var.random_hex}"
}

resource "aws_s3_bucket_public_access_block" "sskai-s3-web-bucket-public-conf" {
  bucket = aws_s3_bucket.sskai-s3-web-bucket.bucket

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "sskai-s3-web-bucket-web-conf" {
  bucket = aws_s3_bucket.sskai-s3-web-bucket.bucket
  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_policy" "sskai-s3-web-bucket-policy" {
  bucket = aws_s3_bucket.sskai-s3-web-bucket.bucket
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.sskai-s3-web-bucket.arn}/*"
      }
    ]
  })
}