#!/bin/bash

set -eo pipefail

set -x

URI_ROOT_PATH=${URI_ROOT_PATH:-}

# Now execute the program. We need to supply a startup script for the
# shell to setup the environment.

MOTD_FILE=motd

if [ -f /opt/terminal/etc/motd ]; then
    MOTD_FILE=/opt/terminal/etc/motd
fi

if [ -f /opt/app-root/etc/motd ]; then
    MOTD_FILE=/opt/app-root/etc/motd
fi

exec /opt/terminal/bin/butterfly.server.py --port=8080 \
    --host=0.0.0.0 --uri-root-path="$URI_ROOT_PATH" --unsecure \
    --i-hereby-declare-i-dont-want-any-security-whatsoever \
    --shell=/opt/terminal/bin/start-terminal.sh --motd=$MOTD_FILE
