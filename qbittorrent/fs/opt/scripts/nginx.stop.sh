#!/usr/bin/env bash

set -Eeuo pipefail

T="/run/nginx/vhost.d/qbittorrent.conf"
rm -f "$T"
curl --unix-socket /run/sockets/nginx.reload.sock http://_/
