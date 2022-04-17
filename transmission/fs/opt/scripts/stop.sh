#!/usr/bin/env bash

set -Eeuo pipefail

T="/run/nginx/vhost.d/transmission.conf"
rm -f "$T"
curl --unix /run/sockets/nginx.reload.sock http://_/

kill -s TERM "$(</opt/transmission.pid)"
