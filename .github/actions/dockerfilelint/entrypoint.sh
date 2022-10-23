#!/bin/sh
set -x

if [ -z "$INPUT_DOCKERFILE" ]; then
    echo "Parameter required: dockerfile"
    exit 1
fi

dockerfilelint "$INPUT_DOCKERFILE" "$@"
