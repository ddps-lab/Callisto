resource "aws_dynamodb_table" "callisto-users" {
    name = "callisto-users-${var.environment}-${var.random_hex}"
    billing_mode = "PAY_PER_REQUEST"

    attribute {
        name = "uid"
        type = "S"
    }

    hash_key = "uid"
}

resource "aws_dynamodb_table" "callisto-jupyter" {
    name = "callisto-jupyter-${var.environment}-${var.random_hex}"
    billing_mode = "PAY_PER_REQUEST"

    attribute {
        name = "uid"
        type = "S"
    }

    attribute {
        name = "user"
        type = "S"
    }

    hash_key = "uid"

    global_secondary_index {
        name = "user-index"
        hash_key = "user"
        projection_type = "ALL"
    }
}