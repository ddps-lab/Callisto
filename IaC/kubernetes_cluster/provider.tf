resource "null_resource" "update-kubeconfig" {
  triggers = {
    cluster_name = module.eks.cluster_name
  }
  provisioner "local-exec" {
    when    = create
    command = <<-EOF
      aws eks update-kubeconfig --name ${var.cluster_name} --profile ${var.awscli_profile} --region ${var.region} && \
      aws eks update-kubeconfig --name ${var.cluster_name} --profile ${var.awscli_profile} --region ${var.region} --kubeconfig ~/.kube/config-eks-${var.cluster_name}
    EOF
  }

  depends_on = [module.eks]
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