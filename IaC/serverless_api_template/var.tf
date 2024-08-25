variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "awscli_profile" {
  type    = string
  default = ""
}

variable "prefix" {
  type    = string
  default = ""
}

variable "container_registry" {
  type    = string
  default = ""
}

variable "container_repository" {
  type    = string
  default = ""
}

variable "container_image_tag" {
  type    = string
  default = "latest"
}

variable "lambda_ram_size" {
  type    = number
  default = 2048
}

variable "lambda_timeout" {
  type    = number
  default = 120
}

variable "eks_cluster_name" {
  type    = string
  default = ""
}

variable "db_api_url" {
  type    = string
  default = ""
}

variable "route53_domain" {
  type    = string
  default = ""
}

variable "region_name" {
  type    = string
  default = ""
}

variable "attach_lambda_policy" {
  type    = bool
  default = false
}

variable "attach_cloudwatch_policy" {
  type    = bool
  default = false
}

variable "attach_eks_policy" {
  type    = bool
  default = false
}
