#!/bin/sh
set -eu

ERROR=0
if [ -z "$BORG_REPO" ]; then
    echo "ERROR: BORG_REPO is not set" >&2
    ERROR=1
fi
if [ -z "$BORG_PASSPHRASE" ]; then
    echo "ERROR: BORG_PASSPHRASE is not set" >&2
    ERROR=1
fi
if [ -z "$BORG_KEYFILE" ]; then
    echo "ERROR: BORG_KEYFILE is not set" >&2
    ERROR=1
fi
if [ $ERROR -ne 0 ]; then exit 1; fi

# Dump passphrase and keyfile data to file and set borg env vars
echo "$BORG_PASSPHRASE" > ~/.borg_passphrase
chmod 400 ~/.borg_passphrase
export BORG_PASSCOMMAND="cat $HOME/.borg_passphrase"
unset BORG_PASSPHRASE

echo "$BORG_KEYFILE" | base64 -d > ~/.borg_keyfile
chmod 400 ~/.borg_keyfile
export BORG_KEY_FILE="$HOME/.borg_keyfile"
unset BORG_KEYFILE

# Create SSH private key
if [ ! -f ~/.ssh/ ]; then mkdir -m 0600 ~/.ssh; fi
echo "$BORG_SSH_PRIVATE_KEY" | base64 -d > ~/.ssh/borg-privatekey
chmod 400 ~/.ssh/borg-privatekey
unset BORG_SSH_PRIVATE_KEY
export BORG_RSH="ssh -i $HOME/.ssh/borg-privatekey"

# Extract borg host/port from BORG_REPO
TEMP_FILE="$(mktemp)"
trap 'rm -f $TEMP_FILE' EXIT INT QUIT TERM
echo "$BORG_REPO" | sed -E 's,ssh://([^@]+)@([^:]+):(\d+)/(.*),\2\n\3,' > "$TEMP_FILE"
while true; do
    read -r BORG_SSH_HOST
    read -r BORG_SSH_PORT
    break
done < "$TEMP_FILE"
rm "$TEMP_FILE"

# Add server public keys to known_hosts
ssh-keyscan -H -p "$BORG_SSH_PORT" "$BORG_SSH_HOST" >"$HOME/.ssh/known_hosts" 2>/dev/null

/bin/sh -c '$@' -- "$@"
