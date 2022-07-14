output "instance_ips" {
  value = [for name, vnic in data.oci_core_vnic.app_vnic : vnic.public_ip_address]
}

output "primary_ip" {
  value = data.oci_core_vnic.app_vnic["primary"].public_ip_address
}

output "deployer_username" {
  value = var.deployer_username
}

output "admin_username" {
  value = var.admin_username
}

output "fqdn" {
  value = cloudflare_record.vault.hostname
}

output "image_ocid" {
  value = lookup(data.oci_core_images.oracle_linux.images[0], "id")
}
