data "aws_ec2_managed_prefix_list" "cloudfront_prefix_list" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "nlb_sg" {
  ingress = [{
    cidr_blocks      = []
    description      = "cloudfront only"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    ipv6_cidr_blocks = []
    prefix_list_ids  = [data.aws_ec2_managed_prefix_list.cloudfront_prefix_list.id]
    security_groups  = []
    self             = false
    }]

  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "alow all outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }]
  vpc_id = module.vpc.vpc.id

  tags = {
    "Name" = "callisto-nlb-sg-${var.environment}-${var.random_string}"
  }
}

module "loadbalancer_controller_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "${var.cluster_name}-lb-controller-sa-role"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller-sa"]
    }
  }
}
resource "helm_release" "aws-load-balancer-controller" {
  namespace = "kube-system"
  name = "aws-load-balancer-controller"
  chart = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  wait = true

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller-sa"
  }

  set {
    name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.loadbalancer_controller_irsa_role.iam_role_arn
  }

  set {
    name = "replicaCount"
    value = "1"
  }

  set {
    name = "nodeSelector.eks\\.amazonaws\\.com/nodegroup"
    value = "${split(":", module.eks.eks_managed_node_groups.callisto_addon_ec2.node_group_id)[1]}"
  }
  
  depends_on = [ module.loadbalancer_controller_irsa_role ]
}

resource "helm_release" "nginx-ingress-controller" {
  namespace        = "ingress-nginx"
  create_namespace = true
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.12.1"
  wait             = true

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-manage-backend-security-group-rules"
    value = "true"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-security-groups"
    value = "${aws_security_group.nlb_sg.id}"
  }

  set {
    name = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-name"
    value = "callisto-nlb-${var.environment}-${var.random_string}"
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

  depends_on = [module.eks, null_resource.update-kubeconfig, helm_release.aws-load-balancer-controller]
}

resource "null_resource" "save-nlb-dns-name" {
  triggers = {
    cluster_name = module.eks.cluster_name
  }
  provisioner "local-exec" {
    when    = create
    command = "sleep 10; kubectl get svc -n ingress-nginx ingress-nginx-controller | tail -n1 | awk {'printf $4'} > ${path.module}/../../nlb_dns_name.txt"
  }

  depends_on = [module.eks, null_resource.update-kubeconfig, helm_release.nginx-ingress-controller]
}