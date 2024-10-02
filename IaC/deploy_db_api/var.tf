# variable "api_list" {
#   type = list(string)
#   default = ["callisto-ddb-jupyter-api"]
# }

variable "region" {
  type = string
  default = "ap-northeast-2"
}

variable "awscli_profile" {
  type = string
  default = "default"
}

variable "route53_domain" {
  type = string
  default = "callisto.ddps.cloud"
}

variable "environment" {}
variable "random_string" {}
variable "eks_cluster_name" {}
variable "container_registry" {}
variable "jupyter_api_container_repository" {}
variable "jupyter_api_image_tag" {} 
variable "jupyter_ddb_table_name" {} 
variable "route53_data" {}
variable "oidc_provider" {}
variable "oidc_provider_arn" {}