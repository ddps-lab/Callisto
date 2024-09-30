provider "aws" {
  region  = var.region
  profile = var.awscli_profile
}

provider "aws" {
  alias = "virginia"
  profile = var.awscli_profile
  region = "us-east-1"
}

provider "random" {}
resource "random_string" "random_string" {
  length = 3
  special = false
  upper = false
  lower = true
}
