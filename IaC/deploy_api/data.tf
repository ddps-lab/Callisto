provider "random" {}

resource "random_id" "random_string" {
  byte_length = 8
}

data "aws_route53_zone" "route53_zone" {
  name = "${var.route53_domain}."
}