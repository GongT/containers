#!/usr/bin/env bash

set -Eeuo pipefail

T="/run/nginx/vhost.d/qbittorrent.conf"
cp -v "/opt/scripts/nginx.conf" "$T"
curl --unix /run/sockets/nginx.reload.sock http://_/
