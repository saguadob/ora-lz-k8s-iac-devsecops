terraform {
  required_version = ">= 1.2.0"

  required_providers {
    oci = {
      source                = "oracle/oci"
      version               = ">= 4.80.0"
      configuration_aliases = [oci.home]
    }
  }
}

resource "oci_bastion_bastion" "test_bastion" {
  #Required
  name             = "bst-app-operator"
  bastion_type     = "standard"
  compartment_id   = var.compartment_id
  target_subnet_id = var.app_k8s_subnet_id

  client_cidr_block_allow_list = var.bastion_client_cidr_block_allow_list
  max_session_ttl_in_seconds   = 1800 #30 minutes
}