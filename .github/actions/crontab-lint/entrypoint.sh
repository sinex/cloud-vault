#!/bin/sh

if [ -z "$INPUT_CRONTAB" ]; then
    echo "Parameter required: crontab"
    exit 1
fi

bash /cron_linter.sh "$INPUT_CRONTAB"
