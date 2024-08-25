provider "aws" {
  #Seoul region
  region  = var.region
  profile = var.awscli_profile
}

provider "aws" {
  region  = "us-east-1"
  profile = var.awscli_profile
  alias   = "virginia"
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.awscli_profile, "--region", var.region]
    }
  }
}

module "vpc" {
  source              = "./vpc"
  vpc_name            = "${var.main_suffix}-callisto-vpc"
  vpc_cidr            = var.vpc_cidr
  current_region      = data.aws_region.current_region.name
  region_azs          = data.aws_availability_zones.region_azs.names
  public_subnet_cidrs = var.public_subnet_cidrs
  # private_subnet_cidrs = var.private_subnet_cidrs
  cluster_name = var.cluster_name
}

# module "efs_csi_irsa_role" {
#   source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

#   role_name             = "${var.cluster_name}-efs-csi"
#   attach_efs_csi_policy = true

#   oidc_providers = {
#     ex = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
#     }
#   }
# }

module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "${var.cluster_name}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
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

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  enable_cluster_creator_admin_permissions = true

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  vpc_id     = module.vpc.vpc.id
  subnet_ids = module.vpc.public_subnet_ids
  # subnet_ids = module.vpc.private_subnet_ids
  control_plane_subnet_ids = concat(module.vpc.public_subnet_ids)
  # control_plane_subnet_ids = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)

  create_cluster_security_group = false
  create_node_security_group    = false

  # fargate_profiles = {
  #   karpenter = {
  #     selectors = [
  #       { namespace = "karpenter" }
  #     ]
  #   }
  # }

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    # aws-efs-csi-driver = {
    #   most_recent = true
    #   service_account_role_arn = module.efs_csi_irsa_role.iam_role_arn
    # }

    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  eks_managed_node_group_defaults = {
    ami_type                   = "BOTTLEROCKET_x86_64"
    instance_types             = ["t3.medium"]
    iam_role_attach_cni_policy = true
  }

  eks_managed_node_groups = {
    callisto_addon_ec2 = {
      min_size     = 1
      max_size     = 4
      desired_size = 1
    }
  }

  tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  depends_on = [
    module.vpc,
  ]
}

resource "aws_ssm_parameter" "param_karpenter_node_role_name" {
  name  = "karpenter_node_role_name_${var.cluster_name}"
  type  = "String"
  value = module.karpenter.node_iam_role_name

  depends_on = [module.karpenter]
}

module "karpenter" {
  source                 = "terraform-aws-modules/eks/aws//modules/karpenter"
  cluster_name           = module.eks.cluster_name
  enable_irsa            = true
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  depends_on = [module.eks]
}

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
    value = data.aws_route53_zone.route53_zone.name
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
    name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.external_dns_irsa_role.iam_role_arn
  }

  depends_on = [module.eks, null_resource.update-kubeconfig, module.external_dns_irsa_role]
}

### DNS mapping
resource "aws_acm_certificate" "certificate" {
  domain_name       = var.route53_domain
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
  zone_id         = data.aws_route53_zone.route53_zone.zone_id

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
    value = data.aws_route53_zone.route53_zone.name
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-backend-protocol"
    value = "http"
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

  set {
    name  = "controller.config.use-forwarded-headers"
    value = "true"
  }

  set {
    name  = "controller.config.force-ssl-redirect"
    value = "true"
  }

  set {
    name  = "controller.config.ssl-redirect"
    value = "true"
  }

  depends_on = [module.eks, null_resource.update-kubeconfig, helm_release.eks-external-dns-integration, aws_acm_certificate_validation.certificate_validation]
}

resource "helm_release" "karpenter" {
  namespace           = "karpenter"
  create_namespace    = true
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "1.0.1"
  wait                = true

  values = [
    <<-EOT
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    # tolerations:
    #   - key: 'eks.amazonaws.com/compute-type'
    #     operator: Equal
    #     value: fargate
    #     effect: "NoSchedule"
    nodeSelector: {}
    replicas: 1
    logLevel: debug
    EOT
  ]

  depends_on = [module.karpenter]
}

# resource "helm_release" "kube-prometheus-stack" {
#   name = "kube-prometheus-stack"
#   namespace = "monitoring"
#   repository = "https://prometheus-community.github.io/helm-charts"
#   chart = "kube-prometheus-stack"
#   version = "62.2.1"
#   create_namespace = true
#   set {
#     name  = "grafana.adminPassword"
#     # need to change with secure value
#     value = "password"
#   }

#   set {
#     name  = "grafana.ingress.enabled"
#     value = "true"
#   }

#   set {
#     name  = "grafana.ingress.ingressClassName"
#     value = "nginx"
#   }

#   set {
#     name  = "grafana.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
#     value = "internet-facing"
#   }

#   set {
#     name  = "grafana.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
#     value = "ip"
#   }
#   set {
#     name  = "grafana.ingress.paths[0]"
#     value = "/monitor"
#   }

#   set {
#     name  = "prometheus-node-exporter.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key"
#     value = "eks.amazonaws.com/compute-type"
#   }

#   set {
#     name  = "prometheus-node-exporter.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator"
#     value = "NotIn"
#   }

#   set {
#     name  = "prometheus-node-exporter.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]"
#     value = "fargate"
#   }

#   depends_on = [ module.eks, helm_release.aws-load-balancer-controller ]
# }

resource "null_resource" "update-kubeconfig" {
  triggers = {
    cluster_name = module.eks.cluster_name
  }
  provisioner "local-exec" {
    when    = create
    command = "aws eks update-kubeconfig --name ${var.cluster_name} --profile ${var.awscli_profile} --region ${var.region}"
  }

  depends_on = [module.eks]
}

# for GPU Instance ??
# resource "null_resource" "install-nvidia-plugin" {
#   triggers = {
#     cluster_name = module.eks.cluster_name
#   }
#   provisioner "local-exec" {
#     when = create
#     command = "kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.15.0/deployments/static/nvidia-device-plugin.yml"
#   }

#   depends_on = [ null_resource.update-kubeconfig ]
# }

resource "null_resource" "create_jupyter_nodepool" {
  provisioner "local-exec" {
    when = create
    command = <<EOT
    echo "${templatefile("${path.module}/templates/jupyter_nodepool.yaml.tpl", {
    eks_cluster_name = module.eks.cluster_name
    node_role_name   = module.karpenter.node_iam_role_name
})}" > ${path.module}/jupyter_nodepool.yaml
    kubectl apply -f ${path.module}/jupyter_nodepool.yaml
    EOT
}

depends_on = [null_resource.update-kubeconfig, helm_release.karpenter]
}

resource "null_resource" "create_ebs_storageclass" {
  provisioner "local-exec" {
    when    = create
    command = <<EOT
    kubectl apply -f ${path.module}/ebs_storageclass.yaml
    EOT
  }

  depends_on = [null_resource.update-kubeconfig, module.eks]
}
