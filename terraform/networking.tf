resource "oci_core_vcn" "vault_vcn" {
  cidr_blocks = [
    "10.14.0.0/16"
  ]
  is_ipv6enabled = true
  compartment_id = var.oci_compartment_ocid
  display_name   = "vault-vcn"
  dns_label      = "vaultvcn"
}

resource "oci_core_subnet" "vault_subnet" {
  cidr_block        = "10.14.42.0/24"
  display_name      = "vault-subnet"
  dns_label         = "vaultsubnet"
  security_list_ids = [oci_core_security_list.vault_security_list.id]
  compartment_id    = var.oci_compartment_ocid
  vcn_id            = oci_core_vcn.vault_vcn.id
  route_table_id    = oci_core_route_table.vault_route_table.id
  dhcp_options_id   = oci_core_vcn.vault_vcn.default_dhcp_options_id
}

resource "oci_core_internet_gateway" "vault_internet_gateway" {
  compartment_id = var.oci_compartment_ocid
  display_name   = "vault-gw"
  vcn_id         = oci_core_vcn.vault_vcn.id
}

resource "oci_core_route_table" "vault_route_table" {
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_vcn.vault_vcn.id
  display_name   = "vault-routetable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.vault_internet_gateway.id
  }
}

resource "oci_core_security_list" "vault_security_list" {
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_vcn.vault_vcn.id
  display_name   = "vault-securitylist"

  egress_security_rules {
    protocol    = "6"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = "22"
      min = "22"
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = "80"
      min = "80"
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = "443"
      min = "443"
    }
  }
}

data "oci_core_vnic_attachments" "app_vnics" {
  for_each            = local.instances
  compartment_id      = var.oci_compartment_ocid
  availability_domain = data.oci_identity_availability_domain.ad.name
  instance_id         = oci_core_instance.instances[each.key].id
}

data "oci_core_vnic" "app_vnic" {
  for_each = local.instances
  vnic_id  = data.oci_core_vnic_attachments.app_vnics[each.key].vnic_attachments[0]["vnic_id"]
}

data "oci_core_private_ips" "app_private_ips" {
  for_each = local.instances
  vnic_id  = data.oci_core_vnic.app_vnic[each.key].id
}

#resource "oci_core_public_ip" "app_public_ip" {
#  compartment_id = var.compartment_ocid
#  lifetime       = "RESERVED"
#  display_name   = "vault-ip"
#
#  # Set to an empty string before destroying to prevent destroy of the reserved IP
#  private_ip_id  = data.oci_core_private_ips.app_private_ips.private_ips[0]["id"]
#  lifecycle {
#    prevent_destroy = true
#  }
#}
