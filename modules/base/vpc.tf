resource "opentelekomcloud_vpc_v1" "this" {
  name = "${var.env_prefix}-vpc"
  cidr = var.vpc_cidr_block
}

resource "opentelekomcloud_vpc_subnet_v1" "private" {
  count = 3

  name       = "${var.env_prefix}-private-subnet-${count.index + 1}"
  cidr       = var.private_subnet_cidr_blocks[count.index]
  vpc_id     = opentelekomcloud_vpc_v1.this.id
  gateway_ip = cidrhost(var.private_subnet_cidr_blocks[count.index], 1)
}

resource "opentelekomcloud_vpc_subnet_v1" "public" {
  count = 3

  name       = "${var.env_prefix}-public-subnet-${count.index + 1}"
  cidr       = var.public_subnet_cidr_blocks[count.index]
  vpc_id     = opentelekomcloud_vpc_v1.this.id
  gateway_ip = cidrhost(var.public_subnet_cidr_blocks[count.index], 1)
}

resource "opentelekomcloud_vpc_eip_v1" "cce" {
  publicip {
    type = "5_bgp"
    name = "${var.env_prefix}-cce-eip"
  }

  bandwidth {
    name        = "${var.env_prefix}-cce-bandwidth"
    size        = 5
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "opentelekomcloud_vpc_eip_v1" "nat" {
  publicip {
    type = "5_bgp"
    name = "${var.env_prefix}-nat-eip"
  }

  bandwidth {
    name        = "${var.env_prefix}-nat-bandwidth"
    size        = 50
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "opentelekomcloud_nat_gateway_v2" "this" {
  name                = "${var.env_prefix}-nat-gateway"
  spec                = "1"
  router_id           = opentelekomcloud_vpc_v1.this.id
  internal_network_id = opentelekomcloud_vpc_subnet_v1.public[0].network_id
}

# SNAT rules are created one at a time: the OTC NAT service returns a
# transient 500 when they are created in parallel on fresh applies.
resource "opentelekomcloud_nat_snat_rule_v2" "private_0" {
  nat_gateway_id = opentelekomcloud_nat_gateway_v2.this.id
  network_id     = opentelekomcloud_vpc_subnet_v1.private[0].network_id
  floating_ip_id = opentelekomcloud_vpc_eip_v1.nat.id
}

resource "opentelekomcloud_nat_snat_rule_v2" "private_1" {
  nat_gateway_id = opentelekomcloud_nat_gateway_v2.this.id
  network_id     = opentelekomcloud_vpc_subnet_v1.private[1].network_id
  floating_ip_id = opentelekomcloud_vpc_eip_v1.nat.id
  depends_on     = [opentelekomcloud_nat_snat_rule_v2.private_0]
}

resource "opentelekomcloud_nat_snat_rule_v2" "private_2" {
  nat_gateway_id = opentelekomcloud_nat_gateway_v2.this.id
  network_id     = opentelekomcloud_vpc_subnet_v1.private[2].network_id
  floating_ip_id = opentelekomcloud_vpc_eip_v1.nat.id
  depends_on     = [opentelekomcloud_nat_snat_rule_v2.private_1]
}

resource "opentelekomcloud_vpc_secgroup_v3" "cluster" {
  name        = "${var.env_prefix}-cluster-sg"
  description = "Security group for CCE cluster"
}

resource "opentelekomcloud_vpc_secgroup_rule_v3" "cluster_inbound" {
  count = 4

  security_group_id = opentelekomcloud_vpc_secgroup_v3.cluster.id
  direction         = ["ingress", "ingress", "ingress", "ingress"][count.index]
  ether_type        = "IPv4"
  protocol          = ["tcp", "tcp", "tcp", "udp"][count.index]
  multi_port        = ["443", "8443", "22", "53"][count.index]
  remote_ip_prefix  = "0.0.0.0/0"

  # work around https://github.com/opentelekomcloud/terraform-provider-opentelekomcloud/issues/3529
  lifecycle {
    ignore_changes = [action, priority]
  }
}

resource "opentelekomcloud_vpc_secgroup_v3" "node" {
  name        = "${var.env_prefix}-node-sg"
  description = "Security group for CCE node pool"
}

resource "opentelekomcloud_vpc_secgroup_rule_v3" "node_inbound" {
  count = 3

  security_group_id = opentelekomcloud_vpc_secgroup_v3.node.id
  direction         = "ingress"
  ether_type        = "IPv4"
  protocol          = "tcp"
  multi_port        = ["10250", "6443", "22"][count.index]
  remote_group_id   = opentelekomcloud_vpc_secgroup_v3.cluster.id

  lifecycle {
    ignore_changes = [action, priority]
  }
}

resource "opentelekomcloud_vpc_secgroup_rule_v3" "node_inbound_icmp" {
  security_group_id = opentelekomcloud_vpc_secgroup_v3.node.id
  direction         = "ingress"
  ether_type        = "IPv4"
  protocol          = "icmp"
  remote_group_id   = opentelekomcloud_vpc_secgroup_v3.cluster.id

  lifecycle {
    ignore_changes = [action, priority]
  }
}
