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
    kubernetes = "v1.25.4"
  }
}
