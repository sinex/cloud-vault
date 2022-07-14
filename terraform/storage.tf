resource "oci_core_volume" "vaultwarden_data" {
    compartment_id = var.oci_compartment_ocid
    availability_domain = data.oci_identity_availability_domain.ad.name
    display_name = "vaultwarden_data"
    size_in_gbs = 50
    vpus_per_gb = 10
}

resource "oci_core_volume_attachment" "vaultwarden_data_attachment" {
    attachment_type = "paravirtualized"
    instance_id = oci_core_instance.instances["primary"].id
    volume_id = oci_core_volume.vaultwarden_data.id
}