#!/usr/bin/env bash

set -Eeuo pipefail

bash /opt/nginx-control.sh stop

rm -f /run/nginx/sockets/mqtt.sock

kill -SIGINT 1
