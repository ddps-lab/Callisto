resource "local_file" "react_env_file" {
    filename = "${path.module}/../../frontend/.env"
    content = <<EOF
VITE_DB_API_URL="https://${var.db_api_url}"
VITE_COGNITO_REGION="${var.region}"
VITE_COGNITO_USER_POOL_ID="${var.callisto_cognito_user_pool_id}"
VITE_COGNITO_CLIENT_ID="${var.callisto_cognito_user_pool_client_id}"
EOF
}

resource "null_resource" "build_react_app" {
  provisioner "local-exec" {
    command = "yarn && yarn build && aws s3 sync ./dist s3://${aws_s3_bucket.callisto_web_bucket.bucket}/ --profile ${var.awscli_profile}"
    working_dir = "${path.module}/../../frontend/"
  }

  depends_on = [ aws_s3_bucket.callisto_web_bucket, local_file.react_env_file ]
}