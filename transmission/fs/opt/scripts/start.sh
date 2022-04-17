#!/usr/bin/env bash

set -Eeuo pipefail

T="/run/nginx/vhost.d/qbittorrent.conf"
cp -v "/opt/scripts/nginx.conf" "$T"
curl --unix /run/sockets/nginx.reload.sock http://_/

rm -f /mnt/data/config.json
ln -s /mnt/config/config.json /mnt/data/config.json

exec /usr/bin/transmission-daemon --config-dir /mnt/data --foreground --no-auth --pid-file /tmp/transmission.pid
