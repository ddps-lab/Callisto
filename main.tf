module "kubernetes_cluster" {
  source          = "./IaC/kubernetes_cluster"
  awscli_profile  = var.awscli_profile
  ami_id          = var.ami_id
  region          = var.region
  environment     = var.environment
  route53_data    = data.aws_route53_zone.route53_zone
  cluster_version = var.k8s_cluster_version
  route53_domain  = var.route53_domain
  random_string   = random_string.random_string.result
  cluster_name    = "callisto-k8s-cluster-${var.environment}-${random_string.random_string.result}"
  providers = {
    aws          = aws
    aws.virginia = aws.virginia
  }
}

module "deploy_db_api" {
  source                           = "./IaC/deploy_db_api"
  route53_domain                   = var.route53_domain
  awscli_profile                   = var.awscli_profile
  region                           = var.region
  environment                      = var.environment
  random_string                    = random_string.random_string.result
  route53_data                     = data.aws_route53_zone.route53_zone
  eks_cluster_name                 = module.kubernetes_cluster.cluster_name
  container_registry               = var.container_registry
  jupyter_ddb_table_name           = module.deploy_db_api.callisto-jupyter_table_name
  jupyter_api_container_repository = var.jupyter_api_container_repository
  jupyter_api_image_tag            = var.jupyter_api_image_tag

  providers = {
    aws          = aws
    aws.virginia = aws.virginia
  }
  depends_on = [module.kubernetes_cluster]
}

module "frontend" {
  source                               = "./IaC/frontend"
  region                               = var.region
  environment                          = var.environment
  random_string                        = random_string.random_string.result
  awscli_profile                       = var.awscli_profile
  route53_domain                       = var.route53_domain
  callisto_cognito_user_pool_id        = module.deploy_db_api.callisto_cognito_user_pool_id
  callisto_cognito_user_pool_client_id = module.deploy_db_api.callisto_cognito_user_pool_client_id
  route53_data                         = data.aws_route53_zone.route53_zone
  api_gateway_id                       = module.deploy_db_api.api_gateway_id

  providers = {
    aws          = aws
    aws.virginia = aws.virginia
  }
  depends_on = [module.deploy_db_api]
}
