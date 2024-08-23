resource "aws_apigatewayv2_api" "callisto_api" {
  name = "Callisto DB REST-API-${random_id.random_string.hex}"
  protocol_type = "HTTP"
  cors_configuration {
    allow_methods = ["*"]
    allow_origins = ["*"]
    allow_headers = ["*"]
  }
}

### lambda permissions
resource "aws_lambda_permission" "callisto_ddb_jupyter_api_permission" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.callisto-ddb-jupyter-api.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.callisto_api.execution_arn}/*/*"
}


resource "aws_lambda_permission" "callisto_ddb_users_api_permission" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.callisto-ddb-users-api.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.callisto_api.execution_arn}/*/*"
}

### integrations
resource "aws_apigatewayv2_integration" "jupyter_integration" {
    api_id = aws_apigatewayv2_api.callisto_api.id
    integration_type = "AWS_PROXY"
    integration_method = "POST"
    integration_uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.callisto-ddb-jupyter-api.arn}/invocations"
    payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "users_integration" {
    api_id = aws_apigatewayv2_api.callisto_api.id
    integration_type = "AWS_PROXY"
    integration_method = "POST"
    integration_uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.callisto-ddb-users-api.arn}/invocations"
    payload_format_version = "2.0"
}

### routes
# /jupyter
resource "aws_apigatewayv2_route" "jupyter_post_route" {
  api_id = aws_apigatewayv2_api.callisto_api.id
  route_key = "POST /jupyter"
  target = "integrations/${aws_apigatewayv2_integration.jupyter_integration.id}"
}

resource "aws_apigatewayv2_route" "jupyter_get_route" {
  api_id = aws_apigatewayv2_api.callisto_api.id
  route_key = "GET /jupyter"
  target = "integrations/${aws_apigatewayv2_integration.jupyter_integration.id}"
}

resource "aws_apigatewayv2_route" "jupyter_put_id_route" {
  api_id = aws_apigatewayv2_api.callisto_api.id
  route_key = "PUT /jupyter/{id}"
  target = "integrations/${aws_apigatewayv2_integration.jupyter_integration.id}"
}

resource "aws_apigatewayv2_route" "jupyter_get_id_route" {
  api_id = aws_apigatewayv2_api.callisto_api.id
  route_key = "GET /jupyter/{id}"
  target = "integrations/${aws_apigatewayv2_integration.jupyter_integration.id}"
}

resource "aws_apigatewayv2_route" "jupyter_delete_id_route" {
  api_id = aws_apigatewayv2_api.callisto_api.id
  route_key = "DELETE /jupyter/{id}"
  target = "integrations/${aws_apigatewayv2_integration.jupyter_integration.id}"
}

# /users
resource "aws_apigatewayv2_route" "users_post_route" {
  api_id = aws_apigatewayv2_api.callisto_api.id
  route_key = "POST /users"
  target = "integrations/${aws_apigatewayv2_integration.users_integration.id}"
}

resource "aws_apigatewayv2_route" "users_get_route" {
  api_id = aws_apigatewayv2_api.callisto_api.id
  route_key = "GET /users"
  target = "integrations/${aws_apigatewayv2_integration.users_integration.id}"
}

resource "aws_apigatewayv2_route" "users_put_id_route" {
  api_id = aws_apigatewayv2_api.callisto_api.id
  route_key = "PUT /users/{id}"
  target = "integrations/${aws_apigatewayv2_integration.users_integration.id}"
}

resource "aws_apigatewayv2_route" "users_get_id_route" {
  api_id = aws_apigatewayv2_api.callisto_api.id
  route_key = "GET /users/{id}"
  target = "integrations/${aws_apigatewayv2_integration.users_integration.id}"
}

resource "aws_apigatewayv2_route" "users_delete_id_route" {
  api_id = aws_apigatewayv2_api.callisto_api.id
  route_key = "DELETE /users/{id}"
  target = "integrations/${aws_apigatewayv2_integration.users_integration.id}"
}

### stage deploy
resource "aws_apigatewayv2_stage" "apigtw_stage" {
  api_id = aws_apigatewayv2_api.callisto_api.id
  name = "callisto-api-dev"
  auto_deploy = true
}

