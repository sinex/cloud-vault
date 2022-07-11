# cloud-vault

[![Linter Checks](https://github.com/sinex/cloud-vault/actions/workflows/ci-lint-checks.yml/badge.svg?branch=master)](https://github.com/sinex/cloud-vault/actions/workflows/ci-lint-checks.yml)
[![Deploy](https://github.com/sinex/cloud-vault/actions/workflows/cd.yml/badge.svg?branch=deploy)](https://github.com/sinex/cloud-vault/actions/workflows/cd.yml)


Automated deployment of Vaultwarden to Oracle Cloud Infrastructure


Features:

- Vaultwarden instance behind a Caddy proxy
- Automatic Cloudflare DNS records
- Cloudflare-integrated fail2ban
- Provisioned on Always-Free tier OCI resources
- Backups to an existing borg repository


## Requirements

- Github
  - Personal Access Token with `write:packages` scope (for pushing images)
  - Personal Access Token with `delete:packages` scope (for CI image cleanup)
  - Personal Access Token with `repo` scope (for Terraform to add secrets)
- Cloudflare
  - API Token with `Zone.DNS` scope (for Terraform to add DNS records)
  - API Token with `Firewall Services:Edit` and `Firewall Services:Read` scope (for fail2ban)
- Terraform Cloud
  - API Token (to plan/apply executions)
- SSH Key for use with Ansible and administrative actions


## Configuration

Environment variables configured in `.env` need to be available in the deployment environment.
It's recommended to use a tool such as `direnv` or `dotenv` to manage this automatically.

An example file is included in this repo containing dummy values for all configuration
```shell
cp .env.example .env
cp vaultwarden.env.example vaultwarden.example
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

### Deployment configuration

```shell
# .env

# Terraform Cloud organisation
TF_CLOUD_ORGANIZATION=

# Terraform Cloud workspace
TF_WORKSPACE=

# Registry prefix for docker containers
CONTAINER_REGISTRY=ghcr.io/username
```

### Infrastructure configuration

Configuration of infrastructure resources is handled by Terraform variables.
This project has been designed with using Terraform Cloud in mind, so any variables set here can also be set in the Terraform Cloud console.

It is recommended that the sensitive values are defined there instead of within the local file.

```terraform
# terraform/terraform.tfvars

# OCI config
oci_tenancy_ocid     = "ocid1.tenancy.oc1.."
oci_user_ocid        = "ocid1.user.oc1.."
oci_compartment_ocid = "ocid1.tenancy.oc1.."
oci_api_fingerprint  = "xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
oci_api_private_key  = <<EOF
-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----
EOF

# API Token with Zone.DNS scope
cloudflare_api_token = "..."

# Domain zone where DNS records will be created
cloudflare_zone      = "example.com"

# Name of the repository hosting this code
github_repository = "cloud-vault"

# Personal Access Token with "repo" scope
github_token      = ""

# User-provided SSH public key. Will be used for both the 'admin' and 'deployer' accounts
admin_ssh_public_key = "ssh-ed25519 AAAAC..."
```

_See `terraform/terraform.tfvars.example` for a description of all available configuration options_

### Application configuration

These values control the settings for both the `vaultwarden` and `caddy` containers
```shell
# .env

# FQDN for the deployed instance
VAULT_DOMAIN=vault.example.com

# Email address for LetsEncrypt registration and Vaultwarden invite sending
VAULT_ADMIN_EMAIL=admin@example.com

# Organisation name to use in vaultwarden
VAULT_ORG_NAME=Vaultwarden
```

### Backup configuration

This stack uses `borg` to automatically create backups.
On startup, the borg container will automatically restore the latest backup if no existing data is found.

If the path defined by `BORG_REPO` does not contain an initialised repository, then it will be initialised using:

```shell
borg init --encryption repokey
```

The repository passphrase will be taken from the `BORG_PASSPHRASE` variable, so it is recommended to generate a secure value _e.g._

```shell
# Save this to BORG_PASSPHRASE in .env
head -c 32 /dev/urandom | base64
```

The remote borg host must be accessible using an SSH private key. It is recommended to generate a dedicated keypair for this:
```shell
# Generate a new SSH key pair
ssh-keygen -C borg@vault -t ed25519 -f ~/.ssh/borg-backup-key

# Get the base64 encoded private key. Add this to .env as BORG_SSH_PRIVATE_KEY
base64 -w0 ~/.ssh/borg-backup-key

# Add the new public key to the authorized_keys file on the server
cat ~/.ssh/borg-backup-key.pub | ssh user@backups.example.com -- "cat - >> ~/.ssh/authorized_keys"

# The new key is no longer required
rm ~/.ssh/borg-backup-key ~/.ssh/borg-backup-key.pub
```

Example borg configuration:

```shell
# .env

# Borg backup repository path. The format must remain as given in the example
BORG_REPO=ssh://user@backups.example.com:22/./vault

# Plain text passphrase for the borg repo.
BORG_PASSPHRASE=cXfddDb1TOhK7hGg/1m8FmlUzC8Z+yrnxkuWw3E9004=

# Base64 encoded SSH private key used to connect to borg remote
BORG_SSH_PRIVATE_KEY=LS0tLS1CRUdJTiBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0KYjNCbGJuTnphQzFyWlhrdGRqRUFBQUFBQkc1dmJtVUFBQUFFYm05dVpRQUFBQUFBQUFBQkFBQUFNd0FBQUF0emMyZ3RaVwpReU5UVXhPUUFBQUNDS0JjRCtGcmpvN0k3L1VaZXdJVHhnaVlZZHRLZjUwaFZtajRHZjRFQ0ZrUUFBQUpDbjhxdUhwL0tyCmh3QUFBQXR6YzJndFpXUXlOVFV4T1FBQUFDQ0tCY0QrRnJqbzdJNy9VWmV3SVR4Z2lZWWR0S2Y1MGhWbWo0R2Y0RUNGa1EKQUFBRUJUY2hJem1yR3NPYTdWTG9RL2VuMnZIdXFYcGRMTU02YXpVS09JcnZMR3VJb0Z3UDRXdU9qc2p2OVJsN0FoUEdDSgpoaDIwcC9uU0ZXYVBnWi9nUUlXUkFBQUFDbUp2Y21kQWRtRjFiSFFCQWdNPQotLS0tLUVORCBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0K
```


### Vaultwarden secrets

Some Vaultwarden variables contain sensitive information, such as SMTP passwords and YubiKey API Keys.
These should be defined in `vaultwarden.env` instead of environment variables in the container.

This file will be mounted into the container where Vaultwarden will read the values.
Any supported Vaultwarden configuration options can be defined here, not just the sensitive ones.

```shell
# vaultwarden.env
VAULT_SMTP_HOST=localhost
VAULT_SMTP_PORT=587
VAULT_SMTP_SECURITY=starttls
VAULT_SMTP_USERNAME=username
VAULT_SMTP_PASSWORD=password
```


_See `.env.example` for a description of all availabl eenvironment variables_


## Deployment

Deployment of the application stack happens in 4 stages:
1. Resource provisioning
1. Host configuration
1. Application deployment
1. Application configuration


### 1. Resource provisioning

This executes Terraform and provisions the required resources in Oracle Cloud

```shell
make infra-create
```

### 2. Host configuration

This executes Ansible against the newly created host, and is responsible for installation of required packages
as well as injecting Docker secrets.

_Any time the values in `.env` or `vaultwarden.env` change, this step must be run again!_

```shell
make infra-configure
```


### 3. Application deployment

Once the host is up and configured, the application is ready to deploy.
This will run `docker stack deploy` and afterwards, the application should be available.

```shell
make app-deploy
```

### 4. Application configuration

In order to access the Vaultwarden `/admin` endpoint, a random `ADMIN_TOKEN` variable needs to be set.
The following make target handles creation of a new token and automates restarting the stack.
The application will be restarted without an `ADMIN_TOKEN` once again when configuration is complete.

```shell
make app-configure
```

## Github CD configuration

CD workflow is defined in `.github/workflows/cd.yml` and is triggered by any branches which start with the string `deploy`

Terraform must be configured to write Github action secrets.
This requires a Personal Access Token with the `repo` scope and the name of the GitHub repository

Define these variables locally or in Terraform Cloud:
```terraform
# terraform.tfvars
github_repository = "cloud-vault"
github_token      = "nCbZafeYI...Dvqrrhyv"
```

There are also a number of GitHub secrets which need to be defined manually for the CD steps to operate correctly.


Note that some of these are not actually _secret_ variables, and so can be hardcoded into the workflow if desired.

| Name                  | Description                                              | Example                     |
|-----------------------|----------------------------------------------------------|-----------------------------|
| DELETE_PACKAGES_TOKEN | GitHub Personal Access Token with `package:delete` scope | XRVkVPBtljAlzl...CadIVthFw' |
| BORG_PASSPHRASE      | Passphrase for the borg backup repository                               | knflRaVmiWxpZpTFoCeBzPbUuvQYzJKQ          |
| BORG_REPO            | Borg ackup repository path                                              | ssh://user@backups.example.com:22/./vault |
| BORG_SSH_PRIVATE_KEY | Base64 encoded SSH private key for accessing borg repository            | jMmhBYlhWdFpXNE...EkFURSBLRVktLS0tLQo=    |
| VAULT_ADMIN_EMAIL    | Email address for LetsEncrypt registration and Vaultwarden invites      | admin@example.com                         |
| VAULT_DOMAIN         | Domain name for DNS records                                             | example.com                               |
| VAULT_HOSTNAME       | Email address used for LetsEncrypt registration and Vaultwarden invites | vault                                     |
| VAULT_ORG_NAME       | Vaultwarden organisation name                                           | Vaultwarden                               |
| VAULT_SMTP_HOST      | Vaultwarden SMTP Host                                                   | mail.example.com                          |
| VAULT_SMTP_PASSWORD  | Vaultwarden SMTP password                                               | LQGXfQqqJYhXjLMY                          |
| VAULT_SMTP_USERNAME  | Vaultwarden SMTP username                                               | user                                      |


In addition, he following are automatically created/updated by Terraform:
- `DEPLOYER_SSH_PRIVATE_KEY`
- `DEPLOYER_USERNAME`
- `PRIMARY_INSTANCE_IP`




## All make targets
```
build-images              │ (docker)    Build images
push-images               │ (docker)    Push images to container registry
infra-create              │ (terraform) Create the infrastructure resources
infra-configure           │ (ansible)   Configure the existing infrastructure
infra-destroy             │ (terraform) Remove the infrastructure resources
app-configure             │ (docker)    Start vaultwarden with a random, temporary ADMIN_TOKEN
app-deploy                │ (docker)    Deploy the vaultwarden application stack
app-destroy               │ (docker)    Stop the vaultwarden application stack
host-shell                │ (ssh)       Start a terminal on the docker host instance
borg-shell                │ (docker)    Start a terminal in the borg container
vaultwarden-shell         │ (docker)    Start a terminal in the vaultwarden container
```
