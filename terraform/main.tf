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
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }

  }
}

# OCI Provider
provider "oci" {
  region       = var.region
  tenancy_ocid = var.oci_tenancy_ocid
  user_ocid    = var.oci_user_ocid
  fingerprint  = var.oci_api_fingerprint
  private_key  = var.oci_api_private_key
}


# Cloudflare Provider
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Github Provider
provider "github" {
  token = var.github_token
}
