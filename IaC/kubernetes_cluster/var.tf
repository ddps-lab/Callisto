variable "vpc_cidr" {
  type    = string
  default = "192.168.0.0/16"
}
variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["192.168.0.0/17", "192.168.128.0/17"]
}

# variable "private_subnet_cidrs" {
#   description = "cidr should be match with private_subnet_number"
#   type = list(string)
#   default = ["192.168.11.0/24", "192.168.21.0/24"]
# }

variable "cluster_name" {}
variable "region" {}
variable "awscli_profile" {}
variable "environment" {}
variable "cluster_version" {}
variable "route53_domain" {}
variable "random_string" {}
variable "ami_id" {}
variable "route53_data" {}