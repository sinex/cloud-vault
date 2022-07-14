data "github_actions_public_key" "main" {
  repository = var.github_repository
}

data "sodium_encrypted_item" "deployer_key" {
    public_key_base64 = data.github_actions_public_key.main.key
    content_base64 = var.deploy_ssh_private_key
}

resource "github_actions_secret" "deployer_ssh_private_key" {
  repository      = var.github_repository
  secret_name     = "DEPLOYER_SSH_PRIVATE_KEY"
  encrypted_value = data.sodium_encrypted_item.deployer_key.encrypted_value_base64
}

resource "github_actions_secret" "deployer_username" {
  repository      = var.github_repository
  secret_name     = "DEPLOYER_USERNAME"
  plaintext_value = var.deployer_username
}

resource "github_actions_secret" "primary_instance_ip" {
  repository      = var.github_repository
  secret_name     = "PRIMARY_INSTANCE_IP"
  plaintext_value = data.oci_core_vnic.app_vnic["primary"].public_ip_address
}