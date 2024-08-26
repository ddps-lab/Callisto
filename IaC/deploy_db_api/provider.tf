# provider "aws" {
#   region = var.region
#   profile = var.awscli_profile
# }

terraform {
  backend "s3" {
    bucket  = "callisto-terraform-state"
    key     = "deploy_db_api/tf.state"
    region  = "ap-northeast-2"
    encrypt = true
  }
}