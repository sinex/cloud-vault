.ONESHELL:
.SHELLFLAGS= -ec

STACK_NAME   ?= vault

CWD          := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
TF_OUTPUTS   := $(CWD)/terraform/.terraform/outputs.json

CONTAINER_REGISTRY_PREFIX :=
ifneq ($(CONTAINER_REGISTRY),)
CONTAINER_REGISTRY_PREFIX := $(CONTAINER_REGISTRY)/
endif

tf_output     = $(shell jq -r .$(1).value $(TF_OUTPUTS))
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


$(TF_OUTPUTS):
	@echo "Reading deployment variables ..."
	( cd terraform && terraform output -json ) > $(TF_OUTPUTS)
	if [ "$$(cat "$(TF_OUTPUTS)")" = "{}" ] || [ "$$(cat "$(TF_OUTPUTS)")" = "" ]; then
		echo "Infrastructure does not seem to be deployed. Run 'make infra-deploy' before deploying the application" >&2
		rm "$(TF_OUTPUTS)"
		exit 1
	fi


build-images: $(addprefix $(CONTAINER_REGISTRY_PREFIX),vault_borg vault_caddy)


push-images:
	docker push $(CONTAINER_REGISTRY_PREFIX)vault_borg
	docker push $(CONTAINER_REGISTRY_PREFIX)vault_caddy


$(CONTAINER_REGISTRY_PREFIX)vault_% : images/%
	docker build -t $@:latest $<


infra-create:
	cd $(CWD)/terraform
	terraform init
	terraform apply
	terraform output -json > $(TF_OUTPUTS)



infra-configure: $(TF_OUTPUTS)
	cd $(CWD)/ansible
	ansible-galaxy install -r requirements.yml --force
	ansible-playbook -vv configure.yml --extra-vars="$$(jq 'with_entries(.value |= .value)' $(TF_OUTPUTS))"

infra-destroy:
	cd terraform
	terraform init
	terraform destroy
	rm -f $(TF_OUTPUTS)


app-configure: $(TF_OUTPUTS)
	@export VAULT_ADMIN_TOKEN="$(call random_token)"
	$(MAKE) --no-print-directory app-destroy
	$(MAKE) --no-print-directory app-deploy
	FQDN=$(call tf_output,fqdn)
	echo "Browse to Vaultwarden admin panel at https://$${FQDN}/admin and use the following token:"
	echo "  $${VAULT_ADMIN_TOKEN}"
	echo ""
	echo "Then press enter to restart the instance."
	read
	unset VAULT_ADMIN_TOKEN
	$(MAKE) --no-print-directory app-destroy
	$(MAKE) --no-print-directory app-deploy


app-deploy: $(TF_OUTPUTS)
	@true
	DOCKER_HOST="ssh://$(call tf_output,deployer_username)@$(call tf_output,primary_ip)"
	set -x
	docker-compose -H "$${DOCKER_HOST}" pull
	docker -H "$${DOCKER_HOST}" stack deploy --compose-file docker-compose.yml --with-registry-auth $(STACK_NAME)
	set +x
	printf '%s' 'Waiting for containers to start ...'
	sleep 3
	until ! docker -H "$${DOCKER_HOST}" service ls --format '{{ .Replicas }}' | grep -q '0/'; do printf '.'; sleep 3; done
	printf '\n'


app-destroy: $(TF_OUTPUTS)
	@true
	DOCKER_HOST="ssh://$(call tf_output,deployer_username)@$(call tf_output,primary_ip)"
	( set -x ; docker -H "$${DOCKER_HOST}" stack rm $(STACK_NAME) )
	printf '%s' 'Waiting for containers to be removed ...'
	until [ -z "$$(docker -H "$${DOCKER_HOST}" stack ps $(STACK_NAME) -q 2>/dev/null)" ]; do printf '.'; sleep 1; done
	printf '\n'


host-shell: $(TF_OUTPUTS)
	@set -x
	ssh "$(call tf_output,admin_username)@$(call tf_output,primary_ip)"


borg-shell: $(TF_OUTPUTS)
	@true
	DOCKER_HOST="ssh://$(call tf_output,deployer_username)@$(call tf_output,primary_ip)"
	set -x
	CONTAINER_ID=$$(docker -H "$${DOCKER_HOST}" ps --latest --filter name=$(STACK_NAME)_borg --format '{{ .ID }}')
	if [ -n "$${CONTAINER_ID}" ]; then
		docker exec -it "$${CONTAINER_ID}" /entrypoint.sh sh
	else
		set +x
		echo "borg container is not running"
	fi


borg-backup: $(TF_OUTPUTS)
	@true
	DOCKER_HOST="ssh://$(call tf_output,deployer_username)@$(call tf_output,primary_ip)"
	set -x
	CONTAINER_ID=$$(docker -H "$${DOCKER_HOST}" ps --latest --filter name=$(STACK_NAME)_borg --format '{{ .ID }}')
	if [ -n "$${CONTAINER_ID}" ]; then
		docker exec -it "$${CONTAINER_ID}" /entrypoint.sh borg create --stats --compression lz4 '::{now}' /data
	else
		set +x
		echo "borg container is not running"
	fi


vaultwarden-shell: $(TF_OUTPUTS)
	@true
	DOCKER_HOST="ssh://$(call tf_output,deployer_username)@$(call tf_output,primary_ip)"
	set -x
	CONTAINER_ID=$$(docker -H "$${DOCKER_HOST}" ps --latest --filter name=$(STACK_NAME)_vaultwarden --format '{{ .ID }}')
	if [ -n "$${CONTAINER_ID}" ]; then
		docker exec -it "$${CONTAINER_ID}" bash
	else
		set +x
		echo "vaultwarden container is not running"
	fi
