FROM caddy:2-alpine

COPY Caddyfile /etc/caddy/Caddyfile

HEALTHCHECK --interval=30s --timeout=2s \
    CMD wget -O /dev/null -Sq localhost:8888/healthcheck

