#!/bin/sh
set -e

ERROR=0

missing_parameter(){
    echo "Parameter required: $1";
    ERROR=1
}

if [ -z "$INPUT_SSH_KEY" ]; then
    missing_parameter ssh_key
fi

if [ -z "$INPUT_SSH_HOST" ]; then
    missing_parameter ssh_host
fi

if [ $ERROR -eq 1 ]; then exit 1; fi

if [ "$INPUT_FORCE_RECREATE" = "true" ]; then
    FORCE_RECREATE_ARG="--force-recreate"
fi

if [ "$INPUT_BUILD" = "true" ]; then
    BUILD_ARG="--build"
fi

mkdir -m 700 -p ~/.ssh
cat << EOF > "$HOME/.ssh/config"
Host *
  StrictHostKeyChecking no
  ControlMaster auto
  ControlPath ~/.ssh/master-%r@%h:%p
EOF
eval $(ssh-agent)
echo "$INPUT_SSH_KEY" | tr -d '\r' | ssh-add -

docker context create remote --docker "host=ssh://$INPUT_SSH_HOST:${INPUT_SSH_PORT:-22}"
docker context use remote

[ "$INPUT_PULL" == 'true' ] && docker-compose pull

docker-compose ${INPUT_COMPOSE_ARGS} -p "${INPUT_STACK_NAME:-stack}" -f ${INPUT_STACK_FILE:-docker-compose.yml} \
    up --detach ${INPUT_UP_ARGS} $BUILD_ARG $FORCE_RECREATE_ARG

docker context use default
docker context rm remote

