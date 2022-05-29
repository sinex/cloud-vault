FROM docker/compose:latest
RUN apk add openssh-client
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
