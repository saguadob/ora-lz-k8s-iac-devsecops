terraform {

  required_providers {
    oci = {
      source                = "oracle/oci"
      configuration_aliases = [oci.home]
      version               = ">= 4.67.3"
    }
  }
}

# Provider configuration required by the OKE installer module
# https://github.com/oracle-terraform-modules/terraform-oci-oke/blob/v4.5.9/docs/quickstart.adoc#provision-using-the-hashicorp-registry-module
provider "oci" {
  tenancy_ocid        = var.tenancy_ocid
  config_file_profile = "DEFAULT"
}

provider "oci" {
  alias               = "home"
  tenancy_ocid        = var.tenancy_ocid
  config_file_profile = "DEFAULT"
}

locals {
  resource_label_prefix = "app1"
  component_versions = {
    kubernetes = "v1.27.2"
  }

  ad_number_to_name = {
    for ad in data.oci_identity_availability_domains.ad_list.availability_domains :
    parseint(substr(ad.name, -1, -1), 10) => ad.name
  }
  ad_numbers = keys(local.ad_number_to_name)
}

data "oci_identity_availability_domains" "ad_list" {
  compartment_id = var.parent_compartmend_ocid
}