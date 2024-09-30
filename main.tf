module "kubernetes_cluster" {
  source          = "./IaC/kubernetes_cluster"
  awscli_profile  = var.awscli_profile
  ami_id          = var.ami_id
  region          = var.region
  environment     = var.environment
  cluster_version = var.k8s_cluster_version
  route53_domain  = var.route53_domain
  random_hex      = random_id.random_string.hex
  cluster_name    = "callisto-k8s-cluster-${var.environment}-${random_id.random_string.hex}"
}

module "deploy_db_api" {
  source         = "./IaC/deploy_db_api"
  route53_domain = var.route53_domain
  awscli_profile = var.awscli_profile
  region         = var.region
  environment    = var.environment
  random_hex     = random_id.random_string.hex

}

module "callisto_jupyter_controller" {
  source               = "./IaC/serverless_api_template"
  function_name        = "callisto_jupyter_controller"
  container_registry   = var.container_registry
  container_repository = "callisto-jupyter-controller"
  container_image_tag  = "latest"
  lambda_ram_size      = 256
  attach_eks_policy    = true
  region               = var.region
  eks_cluster_name     = module.kubernetes_cluster.cluster_name
  db_api_url           = "https://${module.deploy_db_api.api_endpoint_domain_url}"
  route53_domain       = var.route53_domain
  environment          = var.environment
  random_hex           = random_id.random_string.hex


  depends_on = [module.kubernetes_cluster, module.deploy_db_api]
}

module "deploy_api" {
  source                           = "./IaC/deploy_api"
  route53_domain                   = var.route53_domain
  region                           = var.region
  jupyter_controller_function_name = module.callisto_jupyter_controller.function_name
  jupyter_controller_function_arn  = module.callisto_jupyter_controller.function_arn
  environment                      = var.environment
  random_hex                       = random_id.random_string.hex

  depends_on = [module.callisto_jupyter_controller]
}
