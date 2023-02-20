FROM caddy:2.6.4-alpine

COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /

HEALTHCHECK --interval=30s --timeout=2s \
    CMD wget -O /dev/null -Sq localhost:8888/healthcheck

CMD ["/entrypoint.sh"]
