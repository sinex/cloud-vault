#!/bin/sh

if [ -f /run/secrets/DOMAIN ]; then DOMAIN=$(cat /run/secrets/CADDY_DOMAIN); fi
if [ -f /run/secrets/EMAIL ]; then EMAIL=$(cat /run/secrets/CADDY_EMAIL); fi

export DOMAIN
export EMAIL

exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
