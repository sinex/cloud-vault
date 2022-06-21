FROM docker/compose:1.29.2
RUN apk --no-cache add 'openssh-client~=8.3'
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
