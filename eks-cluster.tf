resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = module.eks-cluster.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.53.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role.json
}

locals {
  oidc_issuer_no_scheme = replace(module.eks-cluster.cluster_oidc_issuer_url, "https://", "")
}

data "aws_iam_policy_document" "ebs_csi_driver_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks-cluster.oidc_provider_arn]
    }

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_no_scheme}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_no_scheme}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

  }
}

resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

module "eks-cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.10.0"

  name = var.cluster_name
  kubernetes_version = "1.34"

  addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
  }

  subnet_ids = module.eks-vpc.private_subnets // for Worker Nodes
  vpc_id = module.eks-vpc.vpc_id

  endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    dev = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.small"]
      node_group_name = var.env_prefix

      min_size     = 1
      max_size     = 4
      desired_size = 3

      tags = {
        Name = var.env_prefix
        # Required tags for Cluster Autoscaler
        "k8s.io/cluster-autoscaler/${module.eks-cluster.cluster_name}" = "owned"
        "k8s.io/cluster-autoscaler/enabled"                  = "TRUE"
      }
    }
  }

  fargate_profiles = {
    default = {
      name = "fp-java"
      selectors = [
        {
          namespace = "default"
          labels    = { app: "java-app" }
        }
      ]
    }
  }

  enable_irsa = true

  tags = {
    environment = var.env_prefix
    application = "myapp"
  }
}

# Deploy Cluster Autoscaler using Helm (post-cluster creation)
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.52.1" # appVersion: 1.34.1

  set = [
    {
      name  = "autoDiscovery.clusterName"
      value = module.eks-cluster.cluster_id
    },
    {
      name  = "awsRegion"
      value = "eu-central-1"
    }
  ]

  depends_on = [
    module.eks-cluster.eks_managed_node_groups,
    module.eks-cluster.cluster_addons
  ]
}
