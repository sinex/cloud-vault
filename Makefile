.ONESHELL:
.SHELLFLAGS= -ec

STACK_NAME   := vault

CWD          := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
TF_OUTPUTS   := $(CWD)/infra/terraform/.terraform/outputs.json

CONTAINER_REGISTRY_PREFIX :=
ifneq ($(CONTAINER_REGISTRY),)
CONTAINER_REGISTRY_PREFIX := $(CONTAINER_REGISTRY)/
endif

tf_output     = $(shell jq .$(1).value $(TF_OUTPUTS))
random_token  = $(shell openssl rand -base64 48)

.PHONY: default build-images push-images infra-create infra-configure infra-destroy app-configure app-deploy app-destroy host-shell borg-shell vaultwarden-shell


default:
	@echo "Makefile Targets:"
	echo ""
	echo "build-images              │ (docker)    Build images"
	echo "push-images               │ (docker)    Push images to container registry"
	echo "infra-create              │ (terraform) Create the infrastructure resources"
	echo "infra-configure           │ (ansible)   Configure the existing infrastructure"
	echo "infra-destroy             │ (terraform) Remove the infrastructure resources"
	echo "app-configure             │ (docker)    Start vaultwarden with a random, temporary ADMIN_TOKEN"
	echo "app-deploy                │ (docker)    Deploy the vaultwarden application stack"
	echo "app-destroy               │ (docker)    Stop the vaultwarden application stack"
	echo "host-shell                │ (ssh)       Start a terminal on the docker host instance"
	echo "borg-shell                │ (docker)    Start a terminal in the borg container"
	echo "vaultwarden-shell         │ (docker)    Start a terminal in the vaultwarden container"


build-images: $(addprefix $(CONTAINER_REGISTRY_PREFIX),vault_borg vault_caddy)

push-images:
	docker push $(CONTAINER_REGISTRY_PREFIX)vault_borg
	docker push $(CONTAINER_REGISTRY_PREFIX)vault_caddy

$(CONTAINER_REGISTRY_PREFIX)vault_% : %/
	docker build -t $@:latest $*/

infra-create:
	cd $(CWD)/infra/terraform
	terraform init
	terraform apply
	terraform output -json > $(TF_OUTPUTS)


infra-configure: $(TF_OUTPUTS)
	cd $(CWD)/infra/ansible
	ansible-galaxy install -r requirements.yml
	ansible-playbook -vv configure.yml --extra-vars="$$(jq 'with_entries(.value |= .value)' $(TF_OUTPUTS))"


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
	$(MAKE) --no-print-directory app-destroy
	$(MAKE) --no-print-directory app-deploy
	echo "Connect to the Vaultwarden admin panel using the auth token:"
	echo "  $${VAULT_ADMIN_TOKEN}"
	echo ""
	echo "Then press enter to restart the instance."
	read
	unset VAULT_ADMIN_TOKEN
	$(MAKE) --no-print-directory app-destroy
	$(MAKE) --no-print-directory app-deploy


app-deploy: $(TF_OUTPUTS)
	@true
	set -x
	HOST=$(call tf_output,instance_ip)
	USER=$(call tf_output,deployer_username)
	docker -H "ssh://$${USER}@$${HOST}" stack deploy --compose-file docker-compose.yml --with-registry-auth $(STACK_NAME)


app-destroy: $(TF_OUTPUTS)
	@set -x
	HOST=$(call tf_output,instance_ip)
	USER=$(call tf_output,deployer_username)
	docker -H "ssh://$${USER}@$${HOST}" stack rm $(STACK_NAME)
	set +x
	printf '%s' 'Waiting for containers to be removed ...'
	until [ -z "$$(docker stack ps $(STACK_NAME) -q 2>/dev/null)" ]; do printf '%s' '.'; sleep 1; done
	printf '\n'


host-shell: $(TF_OUTPUTS)
	@set -x
	HOST=$(call tf_output,instance_ip)
	USER=$(call tf_output,admin_username)
	ssh "$${USER}@$${HOST}"


borg-shell: $(TF_OUTPUTS)
	@set -x
	HOST=$(call tf_output,instance_ip)
	USER=$(call tf_output,deployer_username)
	DOCKER_HOST="ssh://$${USER}@$${HOST}"
	CONTAINER_ID=$$(docker ps --latest --filter name=$(STACK_NAME)_borg --format '{{ .ID }}')
	if [ -n "$${CONTAINER_ID}" ]; then
		docker exec -it "$${CONTAINER_ID}" /entrypoint.sh sh
	else
		set +x
		echo "borg container is not running"
	fi


vaultwarden-shell: $(TF_OUTPUTS)
	@set -x
	HOST=$(call tf_output,instance_ip)
	USER=$(call tf_output,deployer_username)
	DOCKER_HOST="ssh://$${USER}@$${HOST}"
	CONTAINER_ID=$$(docker ps --latest --filter name=$(STACK_NAME)_vaultwarden --format '{{ .ID }}')
	if [ -n "$${CONTAINER_ID}" ]; then
		docker exec -it "$${CONTAINER_ID}" bash
	else
		set +x
		echo "vaultwarden container is not running"
	fi
