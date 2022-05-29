resource "oci_core_instance" "instance0" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.oci_compartment_ocid
  display_name        = "${var.hostname}.${var.cloudflare_zone}"
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_gb
  }

  create_vnic_details {
    subnet_id    = oci_core_subnet.test_subnet.id
    display_name = "primaryvnic"
    # Set to false if attaching a reserved public IP
    assign_public_ip = true
    hostname_label   = var.hostname
    nsg_ids          = []
  }

  source_details {
    source_type             = "image"
    source_id               = lookup(data.oci_core_images.test_images.images[0], "id")
    boot_volume_size_in_gbs = var.boot_volume_size_gb
  }

  metadata = {
    ssh_authorized_keys = var.admin_public_key
    user_data           = base64encode(data.template_file.cloud-init.rendered)
  }

  extended_metadata = {}
}

# See https://docs.oracle.com/iaas/images/
data "oci_core_images" "test_images" {
  compartment_id           = var.oci_compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "template_file" "cloud-init" {
  template = file("cloud-init.tpl.yml")
  vars = {
    deployer_username   = var.deployer_username
    deployer_public_key = var.deployer_public_key
    admin_username      = var.admin_username
    admin_public_key    = var.admin_public_key
  }
}
