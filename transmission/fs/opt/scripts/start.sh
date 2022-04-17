#!/usr/bin/env bash

set -Eeuo pipefail

bash /opt/scripts/_reload.sh

touch /data/invalid

exec /usr/bin/transmission-daemon --config-dir /opt/data --foreground --no-auth
