# OCI config
# ----------------------------------------------------------------------------
variable "oci_tenancy_ocid" {
  type = string
}

variable "oci_user_ocid" {
  type = string
}

variable "oci_compartment_ocid" {
  type = string
}

variable "oci_api_fingerprint" {
  type = string
}

variable "oci_api_private_key" {
  type = string
}

# Cloudflare config
# ----------------------------------------------------------------------------

variable "cloudflare_api_token" {
  type = string
}

variable "cloudflare_zone" {
  type = string
}

# Host config
# ----------------------------------------------------------------------------

variable "hostname" {
  type    = string
  default = "vault"
}

variable "deployer_username" {
  type    = string
  default = "deployer"
}

variable "admin_username" {
  type    = string
  default = "admin"
}

variable "admin_public_key" {
  type = string
}

variable "deployer_public_key" {
  type = string
}

# Instance config
# ----------------------------------------------------------------------------

variable "region" {
  type    = string
  default = "ap-sydney-1"
}

variable "instance_shape" {
  type    = string
  default = "VM.Standard.E2.1.Micro"
}

variable "instance_ocpus" {
  type    = number
  default = 1
}

variable "instance_memory_gb" {
  type    = number
  default = 1
}

variable "boot_volume_size_gb" {
  type    = number
  default = 50
  validation {
    condition     = var.boot_volume_size_gb >= 50 && var.boot_volume_size_gb <= 32768
    error_message = "Value of boot_volume_size_gb must be between 50 and 32768 GB."
  }
}
