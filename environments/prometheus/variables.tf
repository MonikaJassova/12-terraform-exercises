variable "env_prefix" {
  type    = string
  default = "prometheus"
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.4.0.0/16"
}

variable "private_subnet_cidr_blocks" {
  type    = list(string)
  default = ["10.4.1.0/24", "10.4.2.0/24", "10.4.3.0/24"]
}

variable "public_subnet_cidr_blocks" {
  type    = list(string)
  default = ["10.4.4.0/24", "10.4.5.0/24", "10.4.6.0/24"]
}

variable "cluster_name" {
  type    = string
  default = "prometheus-cluster"
}

variable "key_pair_name" {
  type    = string
  default = "KeyPair-mjassova2"
}

variable "kubernetes_svc_ip_range" {
  type    = string
  default = "10.87.0.0/16"
}
