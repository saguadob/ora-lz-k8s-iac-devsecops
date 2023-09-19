variable "tenancy_ocid" {}

variable "region" {
  validation {
    condition     = length(trim(var.region, "")) > 0
    error_message = "Validation failed for region: value is required."
  }
}

variable "label_prefix" {
  type = string
}

variable "parent_compartmend_ocid" {
  type = string
}

variable "lz_spoke_vcn_ocid" {
  type = string
}

variable "hub_vcn_cidr" {
  type = string
}

variable "ig_route_table_ocid" {
  type = string
}

variable "lz_spoke_app_subnet_id" {
  type = string
}

variable "lz_spoke_web_subnet_id" {
  type = string
}

variable "bastion_cidr" {
  type = string
}