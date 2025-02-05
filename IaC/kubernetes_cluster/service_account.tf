resource "kubernetes_service_account" "fluentbit_sa" {
  metadata {
    name      = "fluentbit-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.fluentbit_role.arn
    }
  }

  depends_on = [module.eks]
}