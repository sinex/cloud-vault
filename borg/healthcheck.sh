#!/bin/sh

# Interval in seconds to verify the repo when it was last ok
OK_INTERVAL=600

# Interval in seconds to verify the repo when it was last inaccessible
ERROR_INTERVAL=30

STATUS=/tmp/healthcheck.status
STDERR=/tmp/healthcheck.stderr

if [ ! -f "$STATUS" ]; then
    echo 0 > "$STATUS"
    touch -m -t '1970-01-01' "$STATUS"
    touch "$STDERR"
fi

if [ "$(cat "$STATUS")" -eq 0 ]; then
    interval=$OK_INTERVAL
else
    interval=$ERROR_INTERVAL
fi

if [ $(($(date +%s) - $(stat -c %Y "$STATUS"))) -gt $interval ]; then
    borg list >/dev/null 2> "$STDERR"
    echo $? > "$STATUS"
fi

cat "$STDERR"
exit "$(cat "$STATUS")"
