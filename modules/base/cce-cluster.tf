locals {
  cluster_name = var.cluster_name != "" ? var.cluster_name : "${var.env_prefix}-cluster"
}

data "opentelekomcloud_cce_cluster_kubeconfig_v3" "this" {
  cluster_id = opentelekomcloud_cce_cluster_v3.this.id
}

resource "opentelekomcloud_cce_cluster_v3" "this" {
  name                    = local.cluster_name
  cluster_type            = "VirtualMachine"
  flavor_id               = "cce.s1.small"
  vpc_id                  = opentelekomcloud_vpc_v1.this.id
  subnet_id               = opentelekomcloud_vpc_subnet_v1.private[0].network_id
  container_network_type  = "overlay_l2"
  kubernetes_svc_ip_range = var.kubernetes_svc_ip_range
  authentication_mode     = "rbac"
  eip                     = opentelekomcloud_vpc_eip_v1.cce.publicip.0.ip_address

  labels = {
    environment = var.env_prefix
    application = "myapp"
  }
}

resource "opentelekomcloud_cce_node_pool_v3" "this" {
  cluster_id         = opentelekomcloud_cce_cluster_v3.this.id
  name               = var.env_prefix
  os                 = "EulerOS 2.9"
  flavor             = var.node_flavor
  initial_node_count = var.initial_node_count
  availability_zone  = "random"
  key_pair           = var.key_pair_name

  scale_enable             = true
  min_node_count           = var.min_node_count
  max_node_count           = var.max_node_count
  scale_down_cooldown_time = 120
  priority                 = 1

  k8s_tags = {
    "cluster-autoscaler.kubernetes.io/owned" = "TRUE"
  }

  root_volume {
    size       = var.root_volume_size
    volumetype = "SSD"
  }

  data_volumes {
    size       = var.data_volume_size
    volumetype = "SSD"
  }
}

# resource "time_sleep" "wait_for_cluster_ready" {
#   depends_on      = [opentelekomcloud_cce_node_pool_v3.this]
#   create_duration = "300s"
#
#   triggers = {
#     cluster_id = opentelekomcloud_cce_cluster_v3.this.id
#   }
# }

# coredns and everest are pre-installed by CCE (required addons, `require: true`).
# The provider's create POSTs /api/v3/addons unconditionally and fails with 409
# "Addon instance has installed" on any cluster that already has them, so they
# are intentionally not managed here.

data "opentelekomcloud_identity_project_v3" "this" {}

resource "opentelekomcloud_cce_addon_v3" "autoscaler" {
  template_name    = "autoscaler"
  template_version = "1.34.35"
  cluster_id       = opentelekomcloud_cce_cluster_v3.this.id

  values {
    basic = {
      "cceEndpoint"     = "https://cce.eu-de.otc.t-systems.com"
      "ecsEndpoint"     = "https://ecs.eu-de.otc.t-systems.com"
      "image_version"   = "1.34.35"
      "region"          = "eu-de"
      "swr_addr"        = "swr.eu-de.otc.t-systems.com"
      "swr_user"        = "cce-addons"
      "rbac_enabled"    = "true"
      "cluster_version" = "v1.34"
    }
    custom_json = jsonencode({
      agencyConfigurations = [{
        agencyName = ""
        module     = "cluster-autoscaler"
      }]
      alwaysSkipNodesWithSystemPods      = true
      annotations                        = {}
      cluster_id                         = opentelekomcloud_cce_cluster_v3.this.id
      coresTotal                         = 32000
      daemonSetEvictionForEmptyNodes     = false
      daemonSetEvictionForOccupiedNodes  = true
      expander                           = "priority,least-waste,topology-balance"
      ignoreDaemonSetsUtilization        = false
      ignoreLocalVolumeNodeAffinity      = false
      initialNodeGroupBackoffDuration    = "5m"
      logLevel                           = 4
      maxDrainParallelism                = 2
      maxEmptyBulkDeleteFlag             = 10
      maxGracefulTerminationFlag         = 600
      maxNodeGroupBackoffDuration        = "30m"
      maxNodeGroupBinPackingDuration     = "10s"
      maxNodeProvisionTime               = 15
      maxNodesTotal                      = 1000
      maxScaleDownParallelism            = 10
      memoryTotal                        = 128000
      multiAZBalance                     = false
      multiAZEnabled                     = false
      newEphemeralVolumesPodScaleUpDelay = 10
      node_match_expressions             = []
      parallelDrain                      = false
      podDisruptionBudget = {
        create         = true
        maxUnavailable = 1
      }
      resetUnNeededWhenScaleUp          = false
      scaleDownDelayAfterAdd            = 10
      scaleDownDelayAfterDelete         = 10
      scaleDownDelayAfterFailure        = 3
      scaleDownEnabled                  = false
      scaleDownUnneededTime             = 10
      scaleDownUtilizationThreshold     = 0.5
      scaleUpCpuUtilizationThreshold    = 1
      scaleUpMemUtilizationThreshold    = 1
      scaleUpUnscheduledPodEnabled      = true
      scaleUpUtilizationEnabled         = true
      scanInterval                      = "10s"
      skipNodesWithCustomControllerPods = true
      tenant_id                         = data.opentelekomcloud_identity_project_v3.this.id
      tolerations = [
        {
          effect            = "NoExecute"
          key               = "node.kubernetes.io/not-ready"
          operator          = "Exists"
          tolerationSeconds = 60
        },
        {
          effect            = "NoExecute"
          key               = "node.kubernetes.io/unreachable"
          operator          = "Exists"
          tolerationSeconds = 60
        }
      ]
      unremovableNodeRecheckTimeout = 5
    })
    flavor_json = jsonencode({
      description                    = "High avaiable for 50 nodes in cluster"
      is_default                     = false
      name                           = "HA50"
      recommend_cluster_flavor_types = ["small"]
      resources = [{
        name        = "autoscaler"
        limitsCpu   = "1000m"
        requestsCpu = "1000m"
        replicas    = 2
        limitsMem   = "1000Mi"
        requestsMem = "1000Mi"
      }]
      size     = "small"
      category = ["CCE", "Turbo"]
    })
  }

  depends_on = [opentelekomcloud_cce_node_pool_v3.this]
}
