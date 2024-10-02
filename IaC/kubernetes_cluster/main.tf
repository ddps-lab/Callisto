module "vpc" {
  source              = "./vpc"
  vpc_name            = "callisto-vpc-${var.environment}-${var.random_string}"
  vpc_cidr            = var.vpc_cidr
  current_region      = data.aws_region.current_region.name
  region_azs          = data.aws_availability_zones.region_azs.names
  public_subnet_cidrs = var.public_subnet_cidrs
  # private_subnet_cidrs = var.private_subnet_cidrs
  cluster_name = var.cluster_name
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

resource "null_resource" "create_ebs_storageclass" {
  provisioner "local-exec" {
    when    = create
    command = <<EOT
    kubectl apply -f ${path.module}/ebs_storageclass.yaml
    EOT
  }

  depends_on = [null_resource.update-kubeconfig, module.eks]
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
