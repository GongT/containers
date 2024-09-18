#!/usr/bin/env bash

set -Eeuo pipefail

T="/run/nginx/config/vhost.d/qbittorrent.conf"
cp -v "/opt/scripts/nginx.conf" "$T"
curl --unix-socket /run/nginx/sockets/nginx.reload.sock http://_/
