#!/bin/sh
set -ex

ERROR=0

missing_parameter(){
    echo "Parameter required: $1";
    ERROR=1
}

if [ -z "$INPUT_SSH_KEY" ]; then missing_parameter ssh_key; fi
if [ -z "$INPUT_SSH_HOST" ]; then missing_parameter ssh_host; fi
if [ $ERROR -eq 1 ]; then exit 1; fi

mkdir -m 700 ~/.ssh
cat << EOF > "$HOME/.ssh/config"
Host *
  StrictHostKeyChecking no
  ControlMaster auto
  ControlPath ~/.ssh/master-%r@%h:%p
EOF
eval "$(ssh-agent)"
echo "$INPUT_SSH_KEY" | tr -d '\r' | ssh-add -

docker context create remote --docker "host=ssh://$INPUT_SSH_HOST:${INPUT_SSH_PORT:-22}"
docker context use remote

docker stack deploy \
    --compose-file "${INPUT_STACK_FILE:-docker-compose.yml}" \
    "${INPUT_STACK_NAME:-stack}"

#    --with-registry-auth \
docker context use default
docker context rm remote

