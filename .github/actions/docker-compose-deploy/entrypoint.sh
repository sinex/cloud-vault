#!/bin/sh
set -eux

ERROR=0

missing_parameter(){
    echo "Parameter required: $1";
    ERROR=1
}

if [ -z "$SSH_USER" ]; then missing_parameter ssh_user ; fi
if [ -z "$SSH_HOST" ]; then missing_parameter ssh_host ; fi
if [ -z "$SSH_PORT" ]; then missing_parameter ssh_port ; fi
if [ -z "$SSH_KEY" ]; then missing_parameter ssh_key ; fi
if [ -z "$STACK_FILE" ]; then missing_parameter stack_file ; fi
if [ -z "$STACK_NAME" ]; then missing_parameter stack_name ; fi
if [ -z "$DOCKER_REGISTRY" ]; then missing_parameter docker_registry ; fi
if [ -z "$DOCKER_USERNAME" ]; then missing_parameter docker_username ; fi
if [ -z "$DOCKER_PASSWORD" ]; then missing_parameter docker_password ; fi

if [ $ERROR -eq 1 ]; then exit 1; fi


mkdir -m 700 ~/.ssh
#cat << EOF > "$HOME/.ssh/config"
#Host *
#  StrictHostKeyChecking no
#  ControlMaster auto
#  ControlPath ~/.ssh/master-%r@%h:%p
#EOF

eval "$(ssh-agent)"
echo "$SSH_KEY" | tr -d '\r' | ssh-add -
ssh-add -L
ssh-keyscan -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" > ~/.ssh/known_hosts
chmod 600 ~/.ssh/known_hosts


export DOCKER_HOST="ssh://${SSH_USER}@${SSH_HOST}:${SSH_PORT}"

if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
    echo "$DOCKER_PASSWORD" | docker login "$DOCKER_REGISTRY" -u "$DOCKER_USERNAME" --password-stdin
fi;

docker info
docker run hello-world
docker stack deploy --compose-file "${STACK_FILE}" --with-registry-auth "${STACK_NAME}"
