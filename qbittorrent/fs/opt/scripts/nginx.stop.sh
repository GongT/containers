#!/usr/bin/env bash

set -Eeuo pipefail

T="/run/nginx/config/vhost.d/qbittorrent.conf"
rm -f "$T"
curl --unix-socket /run/nginx/sockets/nginx.reload.sock http://_/
