variable "env_prefix" {
  type    = string
  default = "k8s"
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.3.0.0/16"
}

variable "private_subnet_cidr_blocks" {
  type    = list(string)
  default = ["10.3.1.0/24", "10.3.2.0/24", "10.3.3.0/24"]
}

variable "public_subnet_cidr_blocks" {
  type    = list(string)
  default = ["10.3.4.0/24", "10.3.5.0/24", "10.3.6.0/24"]
}

variable "cluster_name" {
  type    = string
  default = "k8s-ansible-cluster"
}

variable "key_pair_name" {
  type    = string
  default = "KeyPair-mjassova2"
}

variable "kubernetes_svc_ip_range" {
  type    = string
  default = "10.86.0.0/16"
}
