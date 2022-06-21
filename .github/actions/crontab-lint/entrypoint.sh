#!/bin/sh

if [ -z "$CRONTAB" ]; then
    echo "Parameter required: crontab"
    exit 1
fi

bash /cron_linter.sh "$CRONTAB"
