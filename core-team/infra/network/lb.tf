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

# RSA key of size 4096 bits
resource "tls_private_key" "rsa-4096-example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "example" {
  private_key_pem = tls_private_key.rsa-4096-example.private_key_pem

  validity_period_hours = 730

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "oci_load_balancer_certificate" "test_certificate" {
  #Required
  certificate_name = "lb-https-web"
  load_balancer_id = oci_load_balancer.webdmz.id

  #Optional
  private_key        = tls_private_key.rsa-4096-example.private_key_pem
  public_certificate = tls_self_signed_cert.example.cert_pem

  lifecycle {
    create_before_destroy = true
  }
}

resource "oci_load_balancer_listener" "test_listener" {
  #Required
  load_balancer_id         = oci_load_balancer.webdmz.id
  name                     = "https_web"
  default_backend_set_name = oci_load_balancer_backend_set.web_backend_set.name
  port                     = 443
  protocol                 = "HTTP"
  routing_policy_name      = oci_load_balancer_load_balancer_routing_policy.web_routing_policy.name

  ssl_configuration {
    certificate_ids                   = []
    certificate_name                  = oci_load_balancer_certificate.test_certificate.certificate_name
    cipher_suite_name                 = "oci-default-ssl-cipher-suite-v1"
    protocols                         = ["TLSv1.2"]
    server_order_preference           = "DISABLED"
    trusted_certificate_authority_ids = []
    verify_depth                      = 1
    verify_peer_certificate           = false
  }
}