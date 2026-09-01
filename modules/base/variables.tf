variable "env_prefix" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "private_subnet_cidr_blocks" {
  type = list(string)

  validation {
    condition     = length(var.private_subnet_cidr_blocks) == 3
    error_message = "Exactly 3 private subnet CIDRs are required (one per SNAT rule)."
  }
}

variable "public_subnet_cidr_blocks" {
  type = list(string)

  validation {
    condition     = length(var.public_subnet_cidr_blocks) == 3
    error_message = "Exactly 3 public subnet CIDRs are required (subnets are created with count = 3)."
  }
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

variable "autoscaler_template_version" {
  type    = string
  default = "1.34.35"
}

variable "autoscaler_image_version" {
  type    = string
  default = "1.34.35"
}

variable "autoscaler_cluster_version" {
  type    = string
  default = "v1.34"
}

variable "autoscaler_cce_endpoint" {
  type    = string
  default = "https://cce.eu-de.otc.t-systems.com"
}

variable "autoscaler_ecs_endpoint" {
  type    = string
  default = "https://ecs.eu-de.otc.t-systems.com"
}

variable "autoscaler_swr_addr" {
  type    = string
  default = "swr.eu-de.otc.t-systems.com"
}

variable "autoscaler_region" {
  type    = string
  default = "eu-de"
}
