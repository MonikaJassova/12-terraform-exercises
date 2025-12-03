data "aws_availability_zones" "azs" {}

module "eks-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.0"

  name = "eks-vpc" // name column of the resource, not Name tag
  cidr = var.vpc_cidr_block
  private_subnets = var.private_subnet_cidr_blocks // one per each AZ in region
  public_subnets = var.public_subnet_cidr_blocks // one per each AZ in region
  azs = data.aws_availability_zones.azs.names // in all region AZs, set dynamically depending on the region

  enable_nat_gateway = true
  single_nat_gateway = true // a shared NAT for all private subnets (to connect to CP in AWS VPC)
  enable_dns_hostnames = true // public and private DNS names in addition to IPs

  // required tags for EKS
  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared" // for K8s Cloud Controller Manager in Control Plane of EKS
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared" // for K8s Cloud Controller Manager in Control Plane of EKS
    "kubernetes.io/role/elb" = 1 // for K8s to know which subnet is public and private
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared" // for K8s Cloud Controller Manager in Control Plane of EKS
    "kubernetes.io/role/internal-elb" = 1 // for K8s to know which subnet is public and private
  }
}