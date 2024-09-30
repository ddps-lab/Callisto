resource "aws_dynamodb_table" "callisto-jupyter" {
  name         = "callisto-jupyter-${var.environment}-${var.random_hex}"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "sub"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "N"
  }

  hash_key  = "sub"
  range_key = "created_at"

  tags = {
    Name        = "callisto-jupyter-${var.environment}-${var.random_hex}"
    Environment = var.environment
  }
}
