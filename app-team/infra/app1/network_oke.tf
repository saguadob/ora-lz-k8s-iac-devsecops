data "oci_core_services" "all_oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

locals {
  vcn_cidr = "10.0.1.0/24" #TODO

  # subnet cidrs - used by subnets
  bastion_subnet = "10.0.1.48/28"

  cp_subnet = "10.0.1.16/28"

  int_lb_subnet = "10.0.1.0/28"

  operator_subnet = ""

  pub_lb_subnet = "10.0.1.0/28"

  workers_subnet = "10.0.1.16/28"

  pods_subnet = "10.0.1.16/28"

  anywhere = "0.0.0.0/0"

  # port numbers
  health_check_port = 10256
  node_port_min     = 30000
  node_port_max     = 32767

  ssh_port = 22

  # protocols
  # # special OCI value for all protocols
  all_protocols = "all"

  # # IANA protocol numbers
  icmp_protocol = 1

  tcp_protocol = 6

  udp_protocol = 17

  # oracle services network
  osn = lookup(data.oci_core_services.all_oci_services.services[0], "cidr_block")

  # Security configuration
  # See https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfig.htm#securitylistconfig
  # if port = -1, allow all ports

  # Security List rules for control plane subnet (Flannel & VCN-Native Pod networking)
  cp_egress_seclist = [
    {
      description      = "Allow Bastion service to communicate to the control plane endpoint. Required for when using OCI Bastion service.",
      destination      = local.cp_subnet,
      destination_type = "CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = 6443,
      stateless        = false
    }
  ]

  cp_ingress_seclist = [
    {
      description = "Allow Bastion service to communicate to the control plane endpoint. Required for when using OCI Bastion service.",
      source      = local.cp_subnet,
      source_type = "CIDR_BLOCK",
      protocol    = local.tcp_protocol,
      port        = 6443,
      stateless   = false
    }
  ]

  # Network Security Group egress rules for control plane subnet (Flannel & VCN-Native Pod networking)
  cp_egress = [
    {
      description      = "Allow Kubernetes Control plane to communicate to the control plane subnet. Required for when using OCI Bastion service.",
      destination      = local.cp_subnet,
      destination_type = "CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = 6443,
      stateless        = false
    },
    {
      description      = "Allow Kubernetes control plane to communicate with OKE",
      destination      = local.osn,
      destination_type = "SERVICE_CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = -1,
      stateless        = false
    },
    {
      description      = "Allow Kubernetes Control plane to communicate with worker nodes",
      destination      = local.workers_subnet,
      destination_type = "CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = 10250,
      stateless        = false
    },
    {
      description      = "Allow ICMP traffic for path discovery to worker nodes",
      destination      = local.workers_subnet,
      destination_type = "CIDR_BLOCK",
      protocol         = local.icmp_protocol,
      port             = -1,
      stateless        = false
    },
  ]

  # Network Security Group ingress rules for control plane subnet (Flannel & VCN-Native Pod networking)
  cp_ingress = concat([
    {
      description = "Allow worker nodes to control plane API endpoint communication"
      protocol    = local.tcp_protocol,
      port        = 6443,
      source      = local.workers_subnet,
      source_type = "CIDR_BLOCK",
      stateless   = false
    },
    {
      description = "Allow worker nodes to control plane communication"
      protocol    = local.tcp_protocol,
      port        = 12250,
      source      = local.workers_subnet,
      source_type = "CIDR_BLOCK",
      stateless   = false
    },
    {
      description = "Allow ICMP traffic for path discovery from worker nodes"
      protocol    = local.icmp_protocol,
      port        = -1,
      source      = local.workers_subnet,
      source_type = "CIDR_BLOCK",
      stateless   = false
    },
  ])

  # Network Security Group ingress rules for control plane subnet (Only VCN-Native Pod networking)
  cp_ingress_npn = [
    {
      description = "Allow pods to control plane API endpoint communication"
      protocol    = local.tcp_protocol,
      port        = 6443,
      source      = local.pods_subnet,
      source_type = "CIDR_BLOCK",
      stateless   = false
    },
    {
      description = "Allow pods to control plane communication"
      protocol    = local.tcp_protocol,
      port        = 12250,
      source      = local.pods_subnet,
      source_type = "CIDR_BLOCK",
      stateless   = false
    },
  ]

  # Network Security Group egress rules for workers subnet (Flannel & VCN-Native Pod networking)
  workers_egress = [
    {
      description      = "Allows communication from (or to) worker nodes.",
      destination      = local.workers_subnet
      destination_type = "CIDR_BLOCK",
      protocol         = local.all_protocols,
      port             = -1,
      stateless        = false
    },
    {
      description      = "Allow ICMP traffic for path discovery",
      destination      = local.anywhere
      destination_type = "CIDR_BLOCK",
      protocol         = local.icmp_protocol,
      port             = -1,
      stateless        = false
    },
    {
      description      = "Allow worker nodes to communicate with OKE",
      destination      = local.osn,
      destination_type = "SERVICE_CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = -1,
      stateless        = false
    },
    {
      description      = "Allow worker nodes to control plane API endpoint communication",
      destination      = local.cp_subnet,
      destination_type = "CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = 6443,
      stateless        = false
    },
    {
      description      = "Allow worker nodes to control plane communication",
      destination      = local.cp_subnet,
      destination_type = "CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = 12250,
      stateless        = false
    }
  ]

  # Network Security Group ingress rules for workers subnet (Flannel & VCN-Native Pod networking)
  workers_ingress = [
    {
      description = "Allow ingress for all traffic to allow pods to communicate between each other on different worker nodes on the worker subnet",
      protocol    = local.all_protocols,
      port        = -1,
      source      = local.workers_subnet,
      source_type = "CIDR_BLOCK",
      stateless   = false
    },
    {
      description = "Allow control plane to communicate with worker nodes",
      protocol    = local.tcp_protocol,
      port        = 10250,
      source      = local.cp_subnet,
      source_type = "CIDR_BLOCK",
      stateless   = false
    },
    {
      description = "Allow path discovery from worker nodes"
      protocol    = local.icmp_protocol,
      port        = -1,
      //this should be local.worker_subnet?
      source      = local.anywhere,
      source_type = "CIDR_BLOCK",
      stateless   = false
    }
  ]

  # Network Security Group egress rules for pods subnet (VCN-Native Pod networking only)
  pods_egress = [
    {
      description      = "Allow pods to communicate with other pods.",
      destination      = local.pods_subnet,
      destination_type = "CIDR_BLOCK",
      protocol         = local.all_protocols,
      port             = -1,
      stateless        = false
    },
    {
      description      = "Allow ICMP traffic for path discovery",
      destination      = local.osn,
      destination_type = "SERVICE_CIDR_BLOCK",
      protocol         = local.icmp_protocol,
      port             = -1,
      stateless        = false
    },
    {
      description      = "Allow pods to communicate with OCI Services",
      destination      = local.osn,
      destination_type = "SERVICE_CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = -1,
      stateless        = false
    },
    {
      description      = "Allow pods to communicate with Kubernetes API server",
      destination      = local.cp_subnet,
      destination_type = "CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = 6443,
      stateless        = false
    }
  ]

  # Network Security Group ingress rules for pods subnet (VCN-Native Pod networking only)
  pods_ingress = [
    {
      description = "Allow Kubernetes control plane to communicate with webhooks served by pods",
      protocol    = local.all_protocols,
      port        = -1,
      source      = local.cp_subnet,
      source_type = "CIDR_BLOCK",
      stateless   = false
    },
    {
      description = "Allow cross-node pod communication when using NodePorts or hostNetwork: true",
      protocol    = local.all_protocols,
      port        = -1,
      source      = local.workers_subnet,
      source_type = "CIDR_BLOCK",
      stateless   = false
    },
    {
      description = "Allow pods to communicate with each other.",
      protocol    = local.all_protocols,
      port        = -1,
      source      = local.pods_subnet,
      source_type = "CIDR_BLOCK",
      stateless   = false
    },
  ]

  # Network Security Group rules for load balancer subnet
  int_lb_egress = [
    {
      description      = "Allow stateful egress to workers. Required for NodePorts",
      destination      = local.workers_subnet,
      destination_type = "CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = "30000-32767",
      stateless        = false
    },
    {
      description      = "Allow ICMP traffic for path discovery to worker nodes",
      destination      = local.workers_subnet,
      destination_type = "CIDR_BLOCK",
      protocol         = local.icmp_protocol,
      port             = -1,
      stateless        = false
    },
    {
      description      = "Allow stateful egress to workers. Required for load balancer http/tcp health checks",
      destination      = local.workers_subnet,
      destination_type = "CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = local.health_check_port,
      stateless        = false
    },
  ]

  # Combine supplied allow list and the public load balancer subnet
  internal_lb_allowed_cidrs = tolist([local.pub_lb_subnet])

  # Create a Cartesian product of allowed cidrs and ports
  internal_lb_allowed_cidrs_and_ports = setproduct(local.internal_lb_allowed_cidrs, [80])

  pub_lb_egress = [
    # {
    #   description      = "Allow stateful egress to internal load balancers subnet on port 80",
    #   destination      = local.int_lb_subnet,
    #   destination_type = "CIDR_BLOCK",
    #   protocol         = local.tcp_protocol,
    #   port             = 80
    #   stateless        = false
    # },
    # {
    #   description      = "Allow stateful egress to internal load balancers subnet on port 443",
    #   destination      = local.int_lb_subnet,
    #   destination_type = "CIDR_BLOCK",
    #   protocol         = local.tcp_protocol,
    #   port             = 443
    #   stateless        = false
    # },
    {
      description      = "Allow stateful egress to workers. Required for NodePorts",
      destination      = local.workers_subnet,
      destination_type = "CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = "30000-32767",
      stateless        = false
    },
    {
      description      = "Allow ICMP traffic for path discovery to worker nodes",
      destination      = local.workers_subnet,
      destination_type = "CIDR_BLOCK",
      protocol         = local.icmp_protocol,
      port             = -1,
      stateless        = false
    },
  ]
}


resource "oci_core_network_security_group" "cp" {
  compartment_id = var.parent_compartmend_ocid
  display_name   = var.label_prefix == "none" ? "control-plane" : "${var.label_prefix}-control-plane"
  vcn_id         = var.lz_spoke_vcn_ocid
}

resource "oci_core_network_security_group_security_rule" "cp_egress" {
  network_security_group_id = oci_core_network_security_group.cp.id
  description               = local.cp_egress[count.index].description
  destination               = local.cp_egress[count.index].destination
  destination_type          = local.cp_egress[count.index].destination_type
  direction                 = "EGRESS"
  protocol                  = local.cp_egress[count.index].protocol

  stateless = false

  dynamic "tcp_options" {
    for_each = local.cp_egress[count.index].protocol == local.tcp_protocol && local.cp_egress[count.index].port != -1 ? [1] : []
    content {
      destination_port_range {
        min = local.cp_egress[count.index].port
        max = local.cp_egress[count.index].port
      }
    }
  }

  dynamic "icmp_options" {
    for_each = local.cp_egress[count.index].protocol == local.icmp_protocol ? [1] : []
    content {
      type = 3
      code = 4
    }
  }

  count = length(local.cp_egress)
}

resource "oci_core_network_security_group_security_rule" "cp_ingress" {
  network_security_group_id = oci_core_network_security_group.cp.id
  description               = local.cp_ingress[count.index].description
  direction                 = "INGRESS"
  protocol                  = local.cp_ingress[count.index].protocol
  source                    = local.cp_ingress[count.index].source
  source_type               = local.cp_ingress[count.index].source_type

  stateless = false

  dynamic "tcp_options" {
    for_each = local.cp_ingress[count.index].protocol == local.tcp_protocol ? [1] : []
    content {
      destination_port_range {
        min = local.cp_ingress[count.index].port
        max = local.cp_ingress[count.index].port
      }
    }
  }

  dynamic "icmp_options" {
    for_each = local.cp_ingress[count.index].protocol == local.icmp_protocol ? [1] : []
    content {
      type = 3
      code = 4
    }
  }

  count = length(local.cp_ingress)

}

# workers nsg and rules
resource "oci_core_network_security_group" "workers" {
  compartment_id = var.parent_compartmend_ocid
  display_name   = var.label_prefix == "none" ? "workers" : "${var.label_prefix}-workers"
  vcn_id         = var.lz_spoke_vcn_ocid
}

resource "oci_core_network_security_group_security_rule" "workers_egress" {
  network_security_group_id = oci_core_network_security_group.workers.id
  description               = local.workers_egress[count.index].description
  destination               = local.workers_egress[count.index].destination
  destination_type          = local.workers_egress[count.index].destination_type
  direction                 = "EGRESS"
  protocol                  = local.workers_egress[count.index].protocol

  stateless = false

  dynamic "tcp_options" {
    for_each = local.workers_egress[count.index].protocol == local.tcp_protocol && local.workers_egress[count.index].port != -1 ? [1] : []
    content {
      destination_port_range {
        min = local.workers_egress[count.index].port
        max = local.workers_egress[count.index].port
      }
    }
  }

  dynamic "icmp_options" {
    for_each = local.workers_egress[count.index].protocol == local.icmp_protocol ? [1] : []
    content {
      type = 3
      code = 4
    }
  }

  count = length(local.workers_egress)
}




resource "oci_core_network_security_group_security_rule" "workers_ingress" {
  network_security_group_id = oci_core_network_security_group.workers.id
  description               = local.workers_ingress[count.index].description
  direction                 = "INGRESS"
  protocol                  = local.workers_ingress[count.index].protocol
  source                    = local.workers_ingress[count.index].source
  source_type               = local.workers_ingress[count.index].source_type

  stateless = false

  dynamic "tcp_options" {
    for_each = local.workers_ingress[count.index].protocol == local.tcp_protocol && local.workers_ingress[count.index].port != -1 ? [1] : []
    content {
      destination_port_range {
        min = local.workers_ingress[count.index].port
        max = local.workers_ingress[count.index].port
      }
    }
  }

  dynamic "icmp_options" {
    for_each = local.workers_ingress[count.index].protocol == local.icmp_protocol ? [1] : []
    content {
      type = 3
      code = 4
    }
  }

  count = length(local.workers_ingress)

}

# add the next 4 rules separately so it can be controlled independently based on which lbs are created
resource "oci_core_network_security_group_security_rule" "workers_ingress_from_int_lb" {
  network_security_group_id = oci_core_network_security_group.workers.id
  description               = "Allow internal load balancers traffic to workers"
  direction                 = "INGRESS"
  protocol                  = local.tcp_protocol
  source                    = local.int_lb_subnet
  source_type               = "CIDR_BLOCK"

  stateless = false

  tcp_options {
    destination_port_range {
      min = local.node_port_min
      max = local.node_port_max
    }
  }



}

resource "oci_core_network_security_group_security_rule" "workers_healthcheck_ingress_from_int_lb" {
  network_security_group_id = oci_core_network_security_group.workers.id
  description               = "Allow internal load balancers health check to workers"
  direction                 = "INGRESS"
  protocol                  = local.tcp_protocol
  source                    = local.int_lb_subnet
  source_type               = "CIDR_BLOCK"

  stateless = false

  tcp_options {
    destination_port_range {
      min = local.health_check_port
      max = local.health_check_port
    }
  }

}

resource "oci_core_network_security_group_security_rule" "workers_ssh_ingress_from_bastion" {
  network_security_group_id = oci_core_network_security_group.workers.id
  description               = "Allow ssh access to workers via Bastion host"
  direction                 = "INGRESS"
  protocol                  = local.tcp_protocol
  source                    = local.bastion_subnet
  source_type               = "CIDR_BLOCK"

  stateless = false

  tcp_options {
    destination_port_range {
      min = local.ssh_port
      max = local.ssh_port
    }
  }

}

# internal lb nsg and rules
resource "oci_core_network_security_group" "int_lb" {
  compartment_id = var.parent_compartmend_ocid
  display_name   = var.label_prefix == "none" ? "int-lb" : "${var.label_prefix}-int-lb"
  vcn_id         = var.lz_spoke_vcn_ocid


}

resource "oci_core_network_security_group_security_rule" "int_lb_egress" {
  network_security_group_id = oci_core_network_security_group.int_lb.id
  description               = local.int_lb_egress[count.index].description
  destination               = local.int_lb_egress[count.index].destination
  destination_type          = local.int_lb_egress[count.index].destination_type
  direction                 = "EGRESS"
  protocol                  = local.int_lb_egress[count.index].protocol

  stateless = false
  # TODO: condition for end-to-end SSL/SSL termination
  dynamic "tcp_options" {
    for_each = local.int_lb_egress[count.index].protocol == local.tcp_protocol && local.int_lb_egress[count.index].port != -1 ? [1] : []
    content {
      destination_port_range {
        min = length(regexall("-", local.int_lb_egress[count.index].port)) > 0 ? tonumber(element(split("-", local.int_lb_egress[count.index].port), 0)) : local.int_lb_egress[count.index].port
        max = length(regexall("-", local.int_lb_egress[count.index].port)) > 0 ? tonumber(element(split("-", local.int_lb_egress[count.index].port), 1)) : local.int_lb_egress[count.index].port
      }
    }
  }

  dynamic "icmp_options" {
    for_each = local.int_lb_egress[count.index].protocol == local.icmp_protocol ? [1] : []
    content {
      type = 3
      code = 4
    }
  }

  count = length(local.internal_lb_allowed_cidrs_and_ports)
}

resource "oci_core_network_security_group_security_rule" "int_lb_ingress" {
  network_security_group_id = oci_core_network_security_group.int_lb.id
  description               = "Allow stateful ingress from ${element(element(local.internal_lb_allowed_cidrs_and_ports, count.index), 0)} on port ${element(element(local.internal_lb_allowed_cidrs_and_ports, count.index), 1)}"
  direction                 = "INGRESS"
  protocol                  = local.tcp_protocol
  source                    = element(element(local.internal_lb_allowed_cidrs_and_ports, count.index), 0)
  source_type               = "CIDR_BLOCK"

  stateless = false

  tcp_options {
    destination_port_range {
      min = length(regexall("-", element(element(local.internal_lb_allowed_cidrs_and_ports, count.index), 1))) > 0 ? element(split("-", element(element(local.internal_lb_allowed_cidrs_and_ports, count.index), 1)), 0) : element(element(local.internal_lb_allowed_cidrs_and_ports, count.index), 1)
      max = length(regexall("-", element(element(local.internal_lb_allowed_cidrs_and_ports, count.index), 1))) > 0 ? element(split("-", element(element(local.internal_lb_allowed_cidrs_and_ports, count.index), 1)), 1) : element(element(local.internal_lb_allowed_cidrs_and_ports, count.index), 1)
    }
  }

  count = length(local.internal_lb_allowed_cidrs_and_ports)
}

