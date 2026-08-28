module "base" {
  source = "../../modules/base"

  env_prefix                 = var.env_prefix
  vpc_cidr_block             = var.vpc_cidr_block
  private_subnet_cidr_blocks = var.private_subnet_cidr_blocks
  public_subnet_cidr_blocks  = var.public_subnet_cidr_blocks
  cluster_name               = var.cluster_name
  key_pair_name              = var.key_pair_name
  kubernetes_svc_ip_range    = var.kubernetes_svc_ip_range
}
