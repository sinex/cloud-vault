data "oci_identity_availability_domain" "ad" {
  compartment_id = var.oci_tenancy_ocid
  ad_number      = 1
}

# See https://docs.oracle.com/iaas/images/
data "oci_core_images" "oracle_linux" {
  compartment_id           = var.oci_compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}
