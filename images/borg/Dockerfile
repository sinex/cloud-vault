FROM alpine:3.17

WORKDIR /root

RUN apk --update --no-cache add 'borgbackup~=1.2.0' 'openssh-client~=9.0' && \
    mkdir /borg_cache && \
    mkdir -m 0700 .cache && \
    ln -sv /borg_cache .cache/borg

COPY crontab /etc/crontabs/root
COPY *.sh /

HEALTHCHECK --interval=30s --timeout=15s CMD [ "/entrypoint.sh", "/healthcheck.sh" ]

VOLUME /borg_cache

ENTRYPOINT ["/entrypoint.sh"]

CMD ["crond", "-f", "-L", "/dev/stdout", "-c", "/etc/crontabs"]
