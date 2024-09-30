module "karpenter" {
  source                 = "terraform-aws-modules/eks/aws//modules/karpenter"
  cluster_name           = module.eks.cluster_name
  enable_irsa            = true
  iam_role_name          = "callisto-karpenter-role-${var.random_hex}"
  node_iam_role_name     = "callisto-karpenter-node-role-${var.random_hex}"
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  depends_on = [module.eks]
}

resource "helm_release" "karpenter" {
  namespace           = "karpenter"
  create_namespace    = true
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
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

resource "aws_ssm_parameter" "param_karpenter_node_role_name" {
  name  = "karpenter_node_role_name_${var.cluster_name}"
  type  = "String"
  value = module.karpenter.node_iam_role_name

  depends_on = [module.karpenter]
}

resource "null_resource" "create_jupyter_nodepool" {
  provisioner "local-exec" {
    when = create
    command = <<EOT
    echo "${templatefile("${path.module}/templates/jupyter_nodepool.yaml.tpl", {
    eks_cluster_name = module.eks.cluster_name
    node_role_name   = module.karpenter.node_iam_role_name
    ami_id           = var.ami_id
})}" > ${path.module}/jupyter_nodepool.yaml
    kubectl apply -f ${path.module}/jupyter_nodepool.yaml
    EOT
}

depends_on = [null_resource.update-kubeconfig, helm_release.karpenter]
}
