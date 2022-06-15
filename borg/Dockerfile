FROM alpine:3.16

RUN apk --update --no-cache add openssh-client borgbackup

COPY crontab /etc/crontabs/root

COPY scripts/ /usr/local/bin/

ARG BORG_SSH_USER
ARG BORG_SSH_HOST
ARG BORG_SSH_PORT
ARG BORG_SSH_KEY

ARG BORG_REPO_PATH
ARG BORG_REPO_KEYFILE
ARG BORG_REPO_PASSPHRASE

RUN mkdir /root/.ssh && \
    echo "$BORG_SSH_KEY" | base64 -d > /root/.ssh/privatekey && \
    chmod 400 /root/.ssh/privatekey

RUN ssh-keyscan -H -p $BORG_SSH_PORT $BORG_SSH_HOST > /root/.ssh/known_hosts

RUN echo "$BORG_REPO_KEYFILE" | base64 -d > /root/.borg_keyfile && \
    echo "$BORG_REPO_PASSPHRASE" > /root/.borg_passphrase

ENV BORG_RSH="ssh -i /root/.ssh/privatekey"
ENV BORG_PASSCOMMAND="cat /root/.borg_passphrase"
ENV BORG_KEY_FILE="/root/.borg_keyfile"
ENV BORG_REPO="ssh://$BORG_SSH_USER@$BORG_SSH_HOST:$BORG_SSH_PORT/$BORG_REPO_PATH"

CMD ["crond", "-f", "-L", "/dev/stdout", "-c", "/etc/crontabs"]
