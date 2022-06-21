FROM alpine:3.16

RUN apk --update --no-cache add 'borgbackup~=1.2.0' 'openssh-client~=9.0'

COPY crontab /etc/crontabs/root
COPY entrypoint.sh /

WORKDIR /root
RUN mkdir /borg_cache && \
    mkdir -m 0700 .cache && \
    ln -sv /borg_cache .cache/borg

VOLUME /borg_cache

ENTRYPOINT ["/entrypoint.sh"]

CMD ["crond", "-f", "-L", "/dev/stdout", "-c", "/etc/crontabs"]
