#!/usr/bin/env bash

set -Eeuo pipefail

declare -r MY_CONFIG=/run/nginx/config/stream.d/mqtt.conf
declare -r NGINX_RELOADER=/run/sockets/nginx.reload.sh

if [[ -e $NGINX_RELOADER ]]; then
	if [[ $1 == start ]]; then
		echo "[nginx] copy config to stream settings" >&2
		cp /opt/mqtt.conf "$MY_CONFIG"
		bash "$NGINX_RELOADER" || true
	elif [[ -e $MY_CONFIG ]]; then
		echo "[nginx] delete config from nginx" >&2
		rm -f "$MY_CONFIG"
		bash "$NGINX_RELOADER" || true
	fi
else
	echo "[ERROR] nginx reload.sh not found!" >&2
fi
