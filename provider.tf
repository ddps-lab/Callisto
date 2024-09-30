provider "aws" {
  region  = var.region
  profile = var.awscli_profile
}

provider "random" {}
resource "random_id" "random_string" {
  byte_length = 2
}
