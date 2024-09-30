data "aws_region" "current_region" {}

data "aws_availability_zones" "region_azs" {
  state = "available"
  filter {
    name = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

data "aws_route53_zone" "route53_zone" {
  name = "${var.route53_domain}."
}