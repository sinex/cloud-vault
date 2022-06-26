.ONESHELL:
.SHELLFLAGS= -ec

CWD          := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
TF_OUTPUTS   := $(CWD)/infra/terraform/.terraform/outputs.json

tf_output     = $(shell jq .$(1).value $(TF_OUTPUTS))
random_token  = $(shell openssl rand -base64 48)

.PHONY: infra-create infra-configure infra-up infra-destroy app-configure app-deploy app-destroy shell


infra-create:
	cd $(CWD)/infra/terraform
	terraform init
	terraform apply
	terraform output -json > $(TF_OUTPUTS)


infra-configure: $(TF_OUTPUTS)
	cd $(CWD)/infra/ansible
	ansible-galaxy install -r requirements.yml
	ansible-playbook -vv configure.yml --extra-vars="$$(jq 'with_entries(.value |= .value)' $(TF_OUTPUTS))"


infra-up:
	$(MAKE) infra-create
	$(MAKE) infra-configure


infra-destroy:
	cd infra/terraform
	terraform init
	terraform destroy
	rm -f $(TF_OUTPUTS)


$(TF_OUTPUTS):
	@echo "Reading deployment variables ..."
	( cd infra/terraform && terraform output -json ) > $(TF_OUTPUTS)
	if [ "$$(cat "$(TF_OUTPUTS)")" = "{}" ]; then
		echo "Infrastructure does not seem to be deployed. Run 'make infra-deploy' before deploying the application" >&2
		exit 1
	fi


app-configure: $(TF_OUTPUTS)
	@export VAULT_ADMIN_TOKEN="$(call random_token)"
	set -x
	HOST=$(call tf_output,instance_ip)
	USER=$(call tf_output,deployer_username)
	DOCKER_HOST="$${DOCKER_HOST}"
	while ! docker-compose -H "ssh://$${USER}@$${HOST}" -p vault down; do echo 'Failed to bring down all services, retrying ...'; done
	docker-compose -H "ssh://$${USER}@$${HOST}" -p vault up -d
	set +x
	echo "Connect to the Vaultwarden admin panel using the auth token:"
	echo "  $${VAULT_ADMIN_TOKEN}"
	echo ""
	echo "Then press enter to restart the instance."
	read
	while ! docker-compose -H "ssh://$${USER}@$${HOST}" -p vault down; do echo 'Failed to bring down all services, retrying ...'; done


app-deploy: $(TF_OUTPUTS)
	@true
	set -x
	HOST=$(call tf_output,instance_ip)
	USER=$(call tf_output,deployer_username)
	docker-compose -H "ssh://$${USER}@$${HOST}" -p vault up -d


app-destroy: $(TF_OUTPUTS)
	@set -x
	HOST=$(call tf_output,instance_ip)
	USER=$(call tf_output,deployer_username)
	while ! docker-compose -H "ssh://$${USER}@$${HOST}" -p vault down; do echo 'Failed to bring down all services, retrying ...'; done


shell: $(TF_OUTPUTS)
	@set -x
	HOST=$(call tf_output,instance_ip)
	USER=$(call tf_output,admin_username)
	ssh "$${USER}@$${HOST}"
