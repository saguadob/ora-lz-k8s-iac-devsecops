resource "oci_core_network_security_group" "oke" {
    #Required
    compartment_id = var.parent_compartmend_ocid
    vcn_id = var.lz_spoke_vcn_ocid
    display_name = "nsg-oke-api-enpoint"
}

resource "oci_core_network_security_group_security_rule" "bastion" {
    #Required
    network_security_group_id = oci_core_network_security_group.oke.id
    direction = "INGRESS"
    protocol = 6 # TCP

    #Optional
    description = "Allow traffic from bastion service to API endpoint"
    destination = oci_containerengine_cluster.test_cluster.endpoints[0].private_endpoint
    source = var.bastion_cidr
    source_type = "CIDR_BLOCK"
    tcp_options {
        destination_port_range {
            #Required
            max = 6443
            min = 6443
        }
    }
}