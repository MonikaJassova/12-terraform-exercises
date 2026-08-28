variable "env_prefix" {
  default = "test"
}

variable "vpc_cidr_block" {
  default = "10.1.0.0/16"
}

variable "private_subnet_cidr_blocks" {
  default = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "public_subnet_cidr_blocks" {
  default = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]
}

variable "cluster_name" {
  default = ""
}

variable "key_pair_name" {
  default = "KeyPair-mjassova2"
}

variable "kubernetes_svc_ip_range" {
  default = "10.84.0.0/16"
}
