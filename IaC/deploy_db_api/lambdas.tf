resource "aws_lambda_function" "callisto-ddb-jupyter-api" {
  function_name = "callisto-ddb-jupyter-api-${var.environment}-${var.random_string}"
  package_type  = "Image"
  architectures = ["x86_64"]
  image_uri     = "${var.container_registry}/${var.jupyter_api_container_repository}:${var.jupyter_api_image_tag}"
  role          = aws_iam_role.lambda_api_role.arn
  memory_size   = 128
  timeout       = 60

  environment {
    variables = {
      REGION            = var.region
      TABLE_NAME        = var.jupyter_ddb_table_name
      TABLE_ARN         = aws_dynamodb_table.callisto-jupyter.arn
      EKS_CLUSTER_NAME  = var.eks_cluster_name
      ROUTE53_DOMAIN    = var.route53_domain
      ECR_URI           = var.container_registry
      OIDC_PROVIDER     = var.oidc_provider
      OIDC_PROVIDER_ARN = var.oidc_provider_arn
    }
  }
}
