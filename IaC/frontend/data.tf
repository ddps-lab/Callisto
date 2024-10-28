data "aws_route53_zone" "route53_zone" {
  name = "${var.route53_domain}."
}
data local_file "nlb_dns_name" {
  filename = "${path.module}/../../nlb_dns_name.txt"
}