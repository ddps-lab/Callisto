provider "aws" {
  region  = var.region
  profile = var.awscli_profile
}

provider "random" {}

resource "random_id" "random_string" {
  byte_length = 8
}

resource "aws_s3_bucket" "tfstate_bucket" {
  bucket        = "callisto-terraform-state-${random_id.random_string.hex}"
  force_destroy = true
}

module "kubernetes_cluster" {
  source         = "./IaC/kubernetes_cluster"
  main_suffix    = var.main_suffix
  awscli_profile = var.awscli_profile
  region         = var.region
}

module "deploy_db_api" {
  source         = "./IaC/deploy_db_api"
  route53_domain = var.route53_domain
  awscli_profile = var.awscli_profile
  region         = var.region
}


module "callisto_jupyter_controller" {
  source               = "./IaC/serverless_api_template"
  prefix               = "callisto_jupyter_controller"
  container_registry   = var.container_registry
  container_repository = "callisto-jupyter-controller"
  container_image_tag  = "latest"
  lambda_ram_size      = 256
  attach_eks_policy    = true
  region_name          = var.region
  awscli_profile       = var.awscli_profile
  region               = var.region
  eks_cluster_name     = module.kubernetes_cluster.cluster_name
  db_api_url           = "https://${module.deploy_db_api.api_endpoint_domain_url}"
  route53_domain       = var.route53_domain

  depends_on = [module.kubernetes_cluster, module.deploy_db_api]
}

module "deploy_api" {
  source                           = "./IaC/deploy_api"
  route53_domain                   = var.route53_domain
  region                           = var.region
  jupyter_controller_function_name = module.callisto_jupyter_controller.function_name
  jupyter_controller_function_arn  = module.callisto_jupyter_controller.function_arn

  depends_on = [module.callisto_jupyter_controller]
}
