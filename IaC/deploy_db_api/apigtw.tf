resource "aws_api_gateway_rest_api" "callisto_db_api" {
  name = "callisto-db-api-${var.environment}-${var.random_string}"
}

### lambda permissions
resource "aws_lambda_permission" "callisto_ddb_jupyter_api_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.callisto-ddb-jupyter-api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.callisto_db_api.execution_arn}/*/*"
}

### /jupyter, /jupyter/{uid} resources
resource "aws_api_gateway_resource" "jupyter_resource" {
  rest_api_id = aws_api_gateway_rest_api.callisto_db_api.id
  parent_id   = aws_api_gateway_rest_api.callisto_db_api.root_resource_id
  path_part   = "jupyter"
}

resource "aws_api_gateway_resource" "jupyter_uid_resource" {
  rest_api_id = aws_api_gateway_rest_api.callisto_db_api.id
  parent_id   = aws_api_gateway_resource.jupyter_resource.id
  path_part   = "{uid}"
}

### /jupyter, /jupyter/{uid} methods

resource "aws_api_gateway_method" "any_jupyter_method" {
  rest_api_id   = aws_api_gateway_rest_api.callisto_db_api.id
  resource_id   = aws_api_gateway_resource.jupyter_resource.id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.callisto_cognito.id
}

resource "aws_api_gateway_method_response" "any_jupyter_method_response" {
  rest_api_id = aws_api_gateway_rest_api.callisto_db_api.id
  resource_id = aws_api_gateway_resource.jupyter_resource.id
  http_method = aws_api_gateway_method.any_jupyter_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method" "any_jupyter_uid_method" {
  rest_api_id   = aws_api_gateway_rest_api.callisto_db_api.id
  resource_id   = aws_api_gateway_resource.jupyter_uid_resource.id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.callisto_cognito.id

  request_parameters = {
    "method.request.path.uid" = true
  }
}

resource "aws_api_gateway_method_response" "any_jupyter_uid_method_response" {
  rest_api_id = aws_api_gateway_rest_api.callisto_db_api.id
  resource_id = aws_api_gateway_resource.jupyter_uid_resource.id
  http_method = aws_api_gateway_method.any_jupyter_uid_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method" "options_jupyter_method" {
  rest_api_id   = aws_api_gateway_rest_api.callisto_db_api.id
  resource_id   = aws_api_gateway_resource.jupyter_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "jupyter_options_lambda_method_response" {
  rest_api_id = aws_api_gateway_rest_api.callisto_db_api.id
  resource_id = aws_api_gateway_resource.jupyter_resource.id
  http_method = aws_api_gateway_method.options_jupyter_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true
    "method.response.header.Access-Control-Allow-Methods"     = true
    "method.response.header.Access-Control-Allow-Origin"      = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method" "options_jupyter_uid_method" {
  rest_api_id   = aws_api_gateway_rest_api.callisto_db_api.id
  resource_id   = aws_api_gateway_resource.jupyter_uid_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "jupyter_uid_options_lambda_method_response" {
  rest_api_id = aws_api_gateway_rest_api.callisto_db_api.id
  resource_id = aws_api_gateway_resource.jupyter_uid_resource.id
  http_method = aws_api_gateway_method.options_jupyter_uid_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true
    "method.response.header.Access-Control-Allow-Methods"     = true
    "method.response.header.Access-Control-Allow-Origin"      = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

### jupyter method integrations
resource "aws_api_gateway_integration" "jupyter_any_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.callisto_db_api.id
  resource_id             = aws_api_gateway_resource.jupyter_resource.id
  http_method             = aws_api_gateway_method.any_jupyter_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.callisto-ddb-jupyter-api.invoke_arn
}

resource "aws_api_gateway_integration" "jupyter_uid_any_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.callisto_db_api.id
  resource_id             = aws_api_gateway_resource.jupyter_uid_resource.id
  http_method             = aws_api_gateway_method.any_jupyter_uid_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.callisto-ddb-jupyter-api.invoke_arn
}

resource "aws_api_gateway_integration" "jupyter_options_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.callisto_db_api.id
  resource_id = aws_api_gateway_resource.jupyter_resource.id
  http_method = aws_api_gateway_method.options_jupyter_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_integration_response" "jupyter_options_lambda_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.callisto_db_api.id
  resource_id = aws_api_gateway_resource.jupyter_resource.id
  http_method = aws_api_gateway_method.options_jupyter_method.http_method
  status_code = aws_api_gateway_method_response.jupyter_options_lambda_method_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token,id-token'"
    "method.response.header.Access-Control-Allow-Methods"     = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"      = "'*'"
  }
}

resource "aws_api_gateway_integration" "jupyter_uid_options_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.callisto_db_api.id
  resource_id = aws_api_gateway_resource.jupyter_uid_resource.id
  http_method = aws_api_gateway_method.options_jupyter_uid_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_integration_response" "jupyter_uid_options_lambda_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.callisto_db_api.id
  resource_id = aws_api_gateway_resource.jupyter_uid_resource.id
  http_method = aws_api_gateway_method.options_jupyter_uid_method.http_method
  status_code = aws_api_gateway_method_response.jupyter_uid_options_lambda_method_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token,id-token'"
    "method.response.header.Access-Control-Allow-Methods"     = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"      = "'*'"
  }
}


### Cognito Authorizer
resource "aws_api_gateway_authorizer" "callisto_cognito" {
  rest_api_id   = aws_api_gateway_rest_api.callisto_db_api.id
  name          = "callisto-cognito-${var.environment}-${var.random_string}"
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.callisto_user_pool.arn]
}

### api deployment
resource "aws_api_gateway_deployment" "callisto_db_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.callisto_db_api.id
  stage_name  = var.environment
}
