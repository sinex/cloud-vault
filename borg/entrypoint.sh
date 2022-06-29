#!/bin/sh
set -e

DATA_DIR="${DATA_DIR:-/data}"

ERROR=0

# Path to Borg repository
if [ -f /run/secrets/BORG_REPO ]; then
    BORG_REPO=$(cat /run/secrets/BORG_REPO)
fi
if [ -z "$BORG_REPO" ]; then
    echo "ERROR: BORG_REPO is not set" >&2 ; ERROR=1
fi

# Passphrase for borg repo
if [ -f /run/secrets/BORG_PASSPHRASE ]; then
    BORG_PASSPHRASE=$(cat /run/secrets/BORG_PASSPHRASE)
fi
if [ -z "$BORG_PASSPHRASE" ]; then
    echo "ERROR: BORG_PASSPHRASE is not set" >&2 ; ERROR=1
fi

# SSH private key for accessing borg remote
if [ -f /run/secrets/BORG_SSH_PRIVATE_KEY_BASE64 ]; then
    BORG_SSH_PRIVATE_KEY_BASE64=$(cat /run/secrets/BORG_SSH_PRIVATE_KEY_BASE64)
fi
if [ -z "$BORG_SSH_PRIVATE_KEY_BASE64" ]; then
    echo "ERROR: BORG_SSH_PRIVATE_KEY_BASE64 is not set" >&2 ; ERROR=1
fi

set -u

if [ $ERROR -ne 0 ]; then exit 1; fi

# Dump passphrase and keyfile data to file and set borg env vars
echo "$BORG_PASSPHRASE" > ~/.borg_passphrase
chmod 400 ~/.borg_passphrase
BORG_PASSCOMMAND="cat $HOME/.borg_passphrase"
unset BORG_PASSPHRASE

# Create SSH private key
if [ ! -d ~/.ssh/ ]; then mkdir -m 0600 ~/.ssh; fi
echo "$BORG_SSH_PRIVATE_KEY" | base64 -d > ~/.ssh/borg-privatekey
chmod 400 ~/.ssh/borg-privatekey
unset BORG_SSH_PRIVATE_KEY
BORG_RSH="ssh -i $HOME/.ssh/borg-privatekey"

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
if [ ! -f "$HOME/.ssh/known_hosts" ]; then
    ssh-keyscan -H -p "$BORG_SSH_PORT" "$BORG_SSH_HOST" >"$HOME/.ssh/known_hosts" 2>/dev/null
fi

# Export required env vars
export BORG_REPO
export BORG_PASSCOMMAND
export BORG_RSH

# Restore the latest backup
if [ ! -f "$DATA_DIR/.backup_restored" ]; then

    # Check repo exists before restoring
    if borg info >/dev/null 2>&1; then
        LATEST_BACKUP=$(borg list --last 1 --format '{archive}')
        echo "Restoring data from backup archive: $LATEST_BACKUP"
        if [ -n "$LATEST_BACKUP" ]; then
            (cd "$DATA_DIR" && borg extract "::$LATEST_BACKUP" --strip-components=1 --list)
        fi
    # Initialise repo if it doesn't exist
    else
        echo "Initialising borg repository: $BORG_REPO"
        borg init -e repokey
        touch "$DATA_DIR/.backup_restored"
        borg create --stats --compression lz4 '::{now}' /data
    fi
fi

/bin/sh -c '$@' -- "$@"
