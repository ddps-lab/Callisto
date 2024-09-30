resource "aws_s3_bucket" "callisto_web_bucket" {
    bucket = "callisto-web-${var.environment}-${var.random_string}"
    force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "callisto-s3-web-bucket-public-conf" {
  bucket = aws_s3_bucket.callisto_web_bucket.bucket

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "callisto-s3-web-bucket-web-conf" {
  bucket = aws_s3_bucket.callisto_web_bucket.bucket
  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_cors_configuration" "callisto-s3-web-cors-conf" {
  bucket = aws_s3_bucket.callisto_web_bucket.bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_policy" "callisto-s3-web-bucket-policy" {
  bucket = aws_s3_bucket.callisto_web_bucket.bucket
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.callisto_web_bucket.arn}/*"
      }
    ]
  })

  depends_on = [ aws_s3_bucket_public_access_block.callisto-s3-web-bucket-public-conf ]
}