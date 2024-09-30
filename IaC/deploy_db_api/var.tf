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
variable "random_hex" {}
variable "eks_cluster_name" {}
variable "container_registry" {}
variable "jupyter_api_container_repository" {}
variable "jupyter_api_image_tag" {} 