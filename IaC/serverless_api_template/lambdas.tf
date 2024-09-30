module "lambda" {
  source                   = "./lambda"
  function_name            = var.function_name
  container_registry       = var.container_registry
  container_repository     = var.container_repository
  container_image_tag      = var.container_image_tag
  ram_mib                  = var.lambda_ram_size
  timeout_s                = var.lambda_timeout
  eks_cluster_name         = var.eks_cluster_name
  attach_cloudwatch_policy = var.attach_cloudwatch_policy
  attach_lambda_policy     = var.attach_lambda_policy
  attach_eks_policy        = var.attach_eks_policy
  region                   = var.region
  db_api_url               = var.db_api_url
  route53_domain           = var.route53_domain
  environment              = var.environment
  random_string               = var.random_string
}
