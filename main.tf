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
  eks_cluster_name = module.kubernetes_cluster.eks_cluster_name
  container_registry = var.container_registry
  jupyter_api_container_repository = var.jupyter_api_container_repository
  jupyter_api_image_tag = var.jupyter_api_image_tag

  depends_on = [module.kubernetes_cluster]
}