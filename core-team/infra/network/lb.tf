resource "oci_core_public_ip" "webdmz" {
  #Required
  compartment_id = var.compartment_id
  lifetime       = "RESERVED"
  display_name   = "ip-dmz-web"
}

resource "oci_load_balancer" "webdmz" {
  #Required
  compartment_id = var.compartment_id
  display_name   = "lb-dmz-web"
  shape          = "flexible"
  subnet_ids     = [
    var.outdoor_subnet_id
  ]

  ip_mode                    = "IPV4"
  is_private                 = false
  network_security_group_ids = [var.dmz_services_nsg_ocid]
  reserved_ips {
    id = oci_core_public_ip.webdmz.id
  }
  shape_details {
    #Required
    maximum_bandwidth_in_mbps = 10
    minimum_bandwidth_in_mbps = 10
  }
}