# This gives back object with certificate-authority among other attributes: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster#attributes-reference
data "aws_eks_cluster" "cluster" {
  name = module.eks-cluster.cluster_name
  depends_on = [module.eks-cluster.cluster_name]
}

# This gives us object with token: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth#attributes-reference  
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks-cluster.cluster_name
  depends_on = [module.eks-cluster.cluster_name]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}

provider "helm" {
  kubernetes {
    host = data.aws_eks_cluster.cluster.endpoint
    token = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  }
}


resource "helm_release" "mysql" {
  name = "mysql-release"
  repository = "https://charts.bitnami.com/bitnami"
  chart = "mysql"
  namespace = "default"
  timeout = "1000" # seconds

  values = ["${file("mysql-values.yaml")}"]

  depends_on = [module.eks-cluster.clusterName]
}
