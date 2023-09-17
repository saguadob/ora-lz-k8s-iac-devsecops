resource "oci_core_public_ip" "webdmz" {
  #Required
  compartment_id = var.compartment_id
  lifetime       = "RESERVED"
  display_name   = "ip-dmz-web"
  lifecycle {
    ignore_changes = [ 
        private_ip_id 
    ]
  }
}

resource "oci_load_balancer" "webdmz" {
  #Required
  compartment_id = var.compartment_id
  display_name   = "lb-dmz-web"
  shape          = "flexible"
  subnet_ids = [
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

resource "oci_load_balancer_backend_set" "web_backend_set" {
  name             = "web-back"
  load_balancer_id = oci_load_balancer.webdmz.id
  policy           = "ROUND_ROBIN"

  health_checker {
    port     = "80"
    protocol = "TCP"
  }
}


resource "oci_load_balancer_load_balancer_routing_policy" "web_routing_policy" {
  #Required
  condition_language_version = "V1"
  load_balancer_id           = oci_load_balancer.webdmz.id
  name                       = "oke_routing"
  rules {
    #Required
    actions {
      #Required
      backend_set_name = oci_load_balancer_backend_set.web_backend_set.name
      name             = "FORWARD_TO_BACKENDSET"
    }
    condition = "http.request.url.path sw '/'"
    name      = "kanban_rule"
  }
}

#listener

resource "oci_load_balancer_listener" "web" {
  load_balancer_id         = oci_load_balancer.webdmz.id
  name                     = "http"
  default_backend_set_name = oci_load_balancer_backend_set.web_backend_set.name
  port                     = 80
  protocol                 = "HTTP"
  routing_policy_name      = oci_load_balancer_load_balancer_routing_policy.web_routing_policy.name

  connection_configuration {
    idle_timeout_in_seconds = "2"
  }
}

resource "oci_load_balancer_backend" "knaboard_01" {
  load_balancer_id = oci_load_balancer.webdmz.id
  backendset_name  = oci_load_balancer_backend_set.web_backend_set.name
  ip_address       = "10.0.1.3"
  port             = 80
  backup           = false
  drain            = false
  offline          = false
  weight           = 100
}