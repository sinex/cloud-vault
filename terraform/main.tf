terraform {

  required_version = "~> 1.2"

  cloud {

  }

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 4.77"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.15"
    }

  }
}

provider "oci" {
  region       = var.region
  tenancy_ocid = var.oci_tenancy_ocid
  user_ocid    = var.oci_user_ocid
  fingerprint  = var.oci_api_fingerprint
  private_key  = var.oci_api_private_key
}

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.oci_tenancy_ocid
  ad_number      = 1
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}


output "instance_ip" {
  value = data.oci_core_vnic.app_vnic.public_ip_address
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
