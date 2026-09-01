output "cluster_id" {
  description = "CCE cluster ID"
  value       = opentelekomcloud_cce_cluster_v3.this.id
}

output "cluster_name" {
  description = "CCE cluster name"
  value       = local.cluster_name
}

output "cluster_eip" {
  description = "CCE cluster external EIP address"
  value       = opentelekomcloud_cce_cluster_v3.this.eip
}

output "vpc_id" {
  description = "VPC ID"
  value       = opentelekomcloud_vpc_v1.this.id
}

output "kubeconfig" {
  description = "Raw CCE cluster kubeconfig YAML"
  value       = data.opentelekomcloud_cce_cluster_kubeconfig_v3.this.kubeconfig
  sensitive   = true
}

output "project_id" {
  description = "OTC project (tenant) ID"
  value       = data.opentelekomcloud_identity_project_v3.this.id
}
