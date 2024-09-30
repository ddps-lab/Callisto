
resource "helm_release" "eks-external-dns-integration" {
  namespace        = "external-dns"
  create_namespace = true
  name             = "external-dns"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "external-dns"
  version          = "8.3.5"
  wait             = true

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.zoneType"
    value = "public"
  }

  set {
    name  = "aws.region"
    value = var.region
  }

  set {
    name  = "txtOwnerId"
    value = module.eks.cluster_name
  }

  set {
    name  = "domainFilters[0]"
    value = var.route53_data.name
  }

  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns-sa"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.external_dns_irsa_role.iam_role_arn
  }

  depends_on = [module.eks, null_resource.update-kubeconfig, module.external_dns_irsa_role]
}


module "external_dns_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.cluster_name}-external-dns"

  attach_external_dns_policy = true
  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-dns:external-dns-sa"]
    }
  }
}

resource "aws_acm_certificate" "certificate" {
  domain_name       = "jupyter.${var.route53_domain}"
  validation_method = "DNS"
}

resource "aws_route53_record" "validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_data.zone_id

  depends_on = [aws_acm_certificate.certificate]
}

resource "aws_acm_certificate_validation" "certificate_validation" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.validation_record : record.fqdn]

  depends_on = [aws_route53_record.validation_record]
}


resource "helm_release" "nginx-ingress-controller" {
  namespace        = "ingress-nginx"
  create_namespace = true
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.11.2"
  wait             = true

  set {
    name  = "controller.service.annotations.external-dns\\.alpha\\.kubernetes\\.io/hostname"
    value = "jupyter.${var.route53_domain}"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-backend-type"
    value = "nlb"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-backend-scheme"
    value = "internet-facing"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-backend-protocol"
    value = "tcp"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-ports"
    value = "https"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
    value = aws_acm_certificate.certificate.arn
  }

  set {
    name  = "controller.service.targetPorts.http"
    value = "http"
  }

  set {
    name  = "controller.service.targetPorts.https"
    value = "http"
  }

  set {
    name  = "controller.service.port.http"
    value = "0"
  }

  depends_on = [module.eks, null_resource.update-kubeconfig, helm_release.eks-external-dns-integration, aws_acm_certificate_validation.certificate_validation]
}