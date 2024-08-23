resource "aws_lambda_function" "callisto-ddb-jupyter-api" {
    function_name = "callisto-ddb-jupyter-api-${random_id.random_string.hex}"
    filename      = "/tmp/callisto-ddb-jupyter-api.zip"
    role          = aws_iam_role.lambda_api_role.arn
    handler       = "index.handler"
    runtime       = "nodejs20.x"
    memory_size   = 128
    timeout       = 60
    depends_on = [ null_resource.download_lambda_codes ]
}

resource "aws_lambda_function" "callisto-ddb-users-api" {
    function_name = "callisto-ddb-users-api-${random_id.random_string.hex}"
    filename      = "/tmp/callisto-ddb-users-api.zip"
    role          = aws_iam_role.lambda_api_role.arn
    handler       = "index.handler"
    runtime       = "nodejs20.x"
    memory_size   = 128
    timeout       = 60
    depends_on = [ null_resource.download_lambda_codes ]
}