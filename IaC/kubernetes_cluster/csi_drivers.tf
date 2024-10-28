resource "helm_release" "ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  version    = "2.36.0"
  namespace  = "kube-system"

  set {
    name  = "controller.replicas"
    value = 1
  }

  set {
    name  = "controller.nodeSelector.eks\\.amazonaws\\.com/nodegroup"
    value = split(":", module.eks.eks_managed_node_groups.callisto_addon_ec2.node_group_id)[1]
  }

  set {
    name = "controller.serviceAccount.create"
    value = "true"
  }

  set {
    name = "controller.serviceAccount.name"
    value = "ebs-csi-controller-sa"
  }

  set {
    name = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.ebs_csi_irsa_role.iam_role_arn
  }
}
