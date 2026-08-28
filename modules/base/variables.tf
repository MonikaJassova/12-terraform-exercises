variable "env_prefix" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "private_subnet_cidr_blocks" {
  type = list(string)
}

variable "public_subnet_cidr_blocks" {
  type = list(string)
}

variable "cluster_name" {
  type    = string
  default = ""
}

variable "key_pair_name" {
  type = string
}

variable "kubernetes_svc_ip_range" {
  type    = string
  default = "10.83.0.0/16"
}

variable "node_flavor" {
  type    = string
  default = "s3.large.2"
}

variable "initial_node_count" {
  type    = number
  default = 3
}

variable "min_node_count" {
  type    = number
  default = 1
}

variable "max_node_count" {
  type    = number
  default = 4
}

variable "root_volume_size" {
  type    = number
  default = 40
}

variable "data_volume_size" {
  type    = number
  default = 100
}
