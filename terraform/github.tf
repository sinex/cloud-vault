resource "github_actions_secret" "deployer_ssh_private_key" {
  repository      = var.github_repository
  secret_name     = "DEPLOYER_SSH_PRIVATE_KEY"
  plaintext_value = tls_private_key.deployer.private_key_pem
}

resource "github_actions_secret" "deployer_username" {
  repository      = var.github_repository
  secret_name     = "DEPLOYER_USERNAME"
  plaintext_value = tls_private_key.deployer.private_key_pem
}

resource "github_actions_secret" "primary_instance_ip" {
  repository      = var.github_repository
  secret_name     = "PRIMARY_INSTANCE_IP"
  plaintext_value = tls_private_key.deployer.private_key_pem
}
