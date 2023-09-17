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

resource "oci_core_security_list" "bastion" {
  #Required
  compartment_id = var.compartment_id
  vcn_id         = var.lz_spoke_vcn_ocid

  display_name = "sl-app-oke-bastionm"
  egress_security_rules {
    #Required
    destination = var.spoke_app_cidr
    protocol    = 6 # TCP

    #Optional
    description      = "Allow traffic from bastion to OKE API endpoint"
    destination_type = "CIDR_BLOCK"
    tcp_options {
      #Optional
      max = 6443
      min = 6443
    }
  }
}

resource "oci_core_subnet" "test_subnet" {
  #Required
  cidr_block     = "10.0.1.48/28"
  compartment_id = var.compartment_id
  vcn_id         = var.lz_spoke_vcn_ocid

  #Optional
  display_name               = "subnet-bastion"
  prohibit_internet_ingress  = true
  prohibit_public_ip_on_vnic = true
  security_list_ids          = [oci_core_security_list.bastion.id]
}

resource "oci_bastion_bastion" "test_bastion" {
  #Required
  name             = "bst-app-operator"
  bastion_type     = "standard"
  compartment_id   = var.compartment_id
  target_subnet_id = oci_core_subnet.test_subnet.id

  client_cidr_block_allow_list = var.bastion_client_cidr_block_allow_list
  max_session_ttl_in_seconds   = 1800 #30 minutes
}

