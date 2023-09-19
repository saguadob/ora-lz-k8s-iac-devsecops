resource "oci_containerengine_cluster" "app" {
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
    is_public_ip_enabled = false
    nsg_ids              = [oci_core_network_security_group.oke.id, oci_core_network_security_group.cp.id]
    subnet_id            = var.lz_spoke_app_subnet_id
  }
  options {
    service_lb_subnet_ids = [var.lz_spoke_web_subnet_id]
  }
  type = "BASIC_CLUSTER"
}

resource "oci_containerengine_node_pool" "app" {
  #Required
  cluster_id     = oci_containerengine_cluster.app.id
  compartment_id = var.parent_compartmend_ocid
  name           = "np-app-01"
  node_shape     = "VM.Standard.A1.Flex"

  kubernetes_version = local.component_versions.kubernetes
  node_config_details {
    #Required

    dynamic "placement_configs" {
      iterator = ad_iterator
      for_each = [for n in local.ad_numbers :
        length(local.ad_numbers) == 1 ? local.ad_number_to_name[1] : local.ad_number_to_name[n]
      ]
      content {
        availability_domain = ad_iterator.value
        subnet_id           = var.lz_spoke_app_subnet_id
      }
    }

    size    = 1
    nsg_ids = [oci_core_network_security_group.workers.id]
  }

  node_shape_config {

    #Optional
    memory_in_gbs = "4"
    ocpus         = "1"
  }

  node_source_details {
    image_id    = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaazhullkkvbfsuooy2nutdxf3v2orqskhzjb3bzgeovnrimpyx3vra"
    source_type = "IMAGE"
  }

}