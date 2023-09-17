# ------------------------------------------------------
# ----- Environment
# ------------------------------------------------------
variable "tenancy_ocid" {}

variable "region" {
  validation {
    condition     = length(trim(var.region, "")) > 0
    error_message = "Validation failed for region: value is required."
  }
}

variable "compartment_id" {
  type = string
}

variable "prefix_service_label" {
  type = string
}
variable "app_k8s_subnet_id" {
  type = string
}
variable "bastion_client_cidr_block_allow_list" {
  type = list(string)
}

variable "spoke_app_cidr" {
  type = string
}

variable "lz_spoke_vcn_ocid" {
  type = string
}