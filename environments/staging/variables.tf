variable "env_prefix" {
  type    = string
  default = "staging"
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.1.0.0/16"
}

variable "private_subnet_cidr_blocks" {
  type    = list(string)
  default = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "public_subnet_cidr_blocks" {
  type    = list(string)
  default = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]
}

variable "cluster_name" {
  type    = string
  default = ""
}

variable "key_pair_name" {
  type    = string
  default = "KeyPair-mjassova2"
}

variable "kubernetes_svc_ip_range" {
  type    = string
  default = "10.84.0.0/16"
}
