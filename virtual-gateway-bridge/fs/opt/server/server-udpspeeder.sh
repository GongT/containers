#!/usr/bin/env bash

set -Eeuo pipefail

sleep 3

exec speederv2_amd64 \
	--disable-color \
	-s \
	-l "127.0.0.1:$SPEEDER_LISTEN_PORT" \
	-r "127.0.0.1:$SPEEDER_CONNECT_PORT" \
	-f 20:10 \
	--mode 1 \
	--mtu "$WIREGUARD_MTU"
