# cloud-vault

[![Linter Checks](https://github.com/sinex/cloud-vault/actions/workflows/ci-lint-checks.yml/badge.svg?branch=master)](https://github.com/sinex/cloud-vault/actions/workflows/ci-lint-checks.yml)


Automated deployment of Vaultwarden to Oracle Cloud Infrastructure


Features:

- Provisioning of Always-Free tier OCI resources
- Vaultwarden instance behind a Caddy proxy
- Backups to an existing borg repository


## Configuration

Terraform setup
```shell
# These variables need to be set in the environment running terraform
# Alternatively, configure the `cloud` block in main.tf

# Terraform Cloud organisation
TF_CLOUD_ORGANIZATION=

# Terraform Cloud workspace
TF_WORKSPACE=
```

Infrastructure configuration

```terraform
# infra/terraform.tfvars

# OCI config
# ----------------------------------------------------------------------------
oci_tenancy_ocid     = "ocid1.tenancy.oc1.."
oci_user_ocid        = "ocid1.user.oc1.."
oci_compartment_ocid = "ocid1.tenancy.oc1.."
oci_api_fingerprint  = "xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
oci_api_private_key  = <<EOF
-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----
EOF


# Cloudflare config
# ----------------------------------------------------------------------------
cloudflare_api_token = "..."
cloudflare_zone      = "example.com"


# Host config
# ----------------------------------------------------------------------------

# Hostname for the instance and DNS A record
hostname = "vault"

# Username for the user used for app deployment
deployer_username = "deployer"

# Username for the sudo-enabled admin user
admin_username = "admin"

# SSH public key used for the 'admin' account on the instance.
# This account will have sudo privileges without requiring a password
admin_public_key = "ssh-ed25519 AAAAC..."

# SSH public key used for the 'deployer' account on the instance
# This account will have the ability to administer docker
deployer_public_key = "ssh-rsa AAAAB..."


# Instance config
# ----------------------------------------------------------------------------
region              = "ap-sydney-1"
instance_shape      = "VM.Standard.E2.1.Micro"
instance_ocpus      = 1
instance_memory_gb  = 1
boot_volume_size_gb = 50
```

Application configuration
```shell
# .env

# Vaultwarden Settings
# -----------------------------------------------------------------------------

# Path on the docker host where persistant data is stored
VAULT_DATA_DIR=/data/vault

# Domain name of the deployment host
VAULT_DOMAIN=vault.example.com

# Email address for LetsEncrypt registration and Vaultwarden invites
VAULT_ADMIN_EMAIL=admin@example.com

# Organisation name to use in vaultwarden
VAULT_ORG_NAME=Vaultwarden

# Vaultwarden SMTP configuration
VAULT_SMTP_HOST=localhost
VAULT_SMTP_PORT=587
VAULT_SMTP_SECURITY=starttls
VAULT_SMTP_USERNAME=username
VAULT_SMTP_PASSWORD=password


# Borg Backup Settings
# -----------------------------------------------------------------------------

# borg repository path must be in this format
BORG_REPO=ssh://user@backups.example.com:22/./vault

# Plain text passphrase for the borg repo
BORG_PASSPHRASE=

# Base64 encoded keyfile for the borg repo
BORG_KEYFILE=

# Base64 encoded SSH private key used to connect to borg remote
BORG_SSH_PRIVATE_KEY=

```


## Usage

```shell
# Provision OCI resources
make infra-create

# Start Vaultwarden
make app-deploy

# Start Vaultwarden with a random ADMIN_TOKEN
make app-configure

# Connect to the server using SSH
make shell

# Stop Vaultwarden
make app-destroy

# Destroy OCI resources
make infra-destroy
```