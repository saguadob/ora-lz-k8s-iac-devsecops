/**
module "oke" {
  source  = "oracle-terraform-modules/oke/oci"
  version = "4.5.9"

  # Mandatory Variables
  home_region = var.region
  region      = var.region
  tenancy_id  = var.tenancy_ocid

  #Governance
  compartment_id = var.parent_compartmend_ocid
  label_prefix   = local.resource_label_prefix

  #Networking
  create_vcn         = false
  vcn_id             = var.lz_spoke_vcn_ocid
  ig_route_table_id  = var.ig_route_table_ocid
  nat_route_table_id = var.ig_route_table_ocid


  #Bastion & Operator
  create_bastion_host    = false
  create_bastion_service = false
  create_operator        = false

  #OKE
  kubernetes_version     = local.component_versions.kubernetes
  control_plane_type     = "private"
  worker_type            = "private"
  allow_node_port_access = false

  node_pools = {
    # Basic node pool
    np1 = {
      shape          = "VM.Standard.A1.Flex"
      ocpus          = 1
      memory         = 4
      node_pool_size = 1
    }
  }
  #node_pool_os         = "Oracle Linux"
  #node_pool_os_version = "8"

  load_balancers            = "internal"
  preferred_load_balancer   = "internal"
  internal_lb_allowed_cidrs = [var.hub_vcn_cidr]

  control_plane_allowed_cidrs = ["0.0.0.0/0"]

  providers = {
    oci.home = oci.home
  }
} **/

resource "oci_containerengine_cluster" "test_cluster" {
  #Required
  compartment_id     = var.parent_compartmend_ocid
  kubernetes_version = local.component_versions.kubernetes
  name               = "oke-change-me"
  vcn_id             = var.lz_spoke_vcn_ocid

  #Optional
  cluster_pod_network_options {
    #Required
    cni_type = "FLANNEL_OVERLAY"
  }

  endpoint_config {

    # Optional
    is_public_ip_enabled = false
    # nsg_ids = var.cluster_endpoint_config_nsg_ids
    subnet_id = var.lz_spoke_app_subnet_id
  }
  options {
    service_lb_subnet_ids = [var.lz_spoke_web_subnet_id]
  }
  type = "BASIC_CLUSTER"
}