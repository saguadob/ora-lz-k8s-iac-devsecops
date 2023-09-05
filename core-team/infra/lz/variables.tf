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

variable "enclosing_compartment" {
  type = string
}

variable "prefix_service_label" {
  type = string
}