#!/usr/bin/env bash

set -Eeuo pipefail

PROJ=liverecord

apply_gateway() {
	local F=$1 T="/run/nginx/vhost.d/${PROJ}.conf"
	if [ -z "$F" ]; then
		rm -v "${T}"
	else
		cp -v "/opt/${F}.conf" "${T}"
	fi
	curl --unix /run/sockets/nginx.reload.sock http://_/ || true
}
trap 'echo "got SIGINT"' INT

echo "reload nginx..."
apply_gateway liverecord.nginx.gateway

echo "starting...."
/usr/sbin/nginx &
wait $!

/usr/sbin/nginx -s stop || true

echo "will shutdown"
apply_gateway ''
echo "byebye."
exit 0
