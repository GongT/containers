#!/usr/bin/env bash

set -Eeuo pipefail

T="/run/nginx/vhost.d/qbittorrent.conf"
cp -v "/opt/scripts/nginx.conf" "$T"
curl --unix /run/sockets/nginx.reload.sock http://_/

rm -f /mnt/data/settings.json
ln -s /mnt/data/config.json /mnt/data/settings.json

kill -s HUP "$(</tmp/transmission.pid)"
