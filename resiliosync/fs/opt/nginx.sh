#!/usr/bin/env bash

set -Eeuo pipefail

apply_gateway() {
	F=$1 T="/run/nginx/vhost.d/ResilioSync.conf"
	if [ -z "$F" ]; then
		rm -v "${T}"
	else
		cp -v "/opt/${F}.conf" "${T}"
	fi
	echo 'GET /' | ncat --unixsock /run/sockets/nginx.reload.sock
}
trap 'echo "got SIGINT"' INT

echo "reload nginx..."
apply_gateway nginx

echo "starting...."
rm -f /run/sockets/resiliosync.sock
mkdir -p /var/log/nginx/
nginx &
wait $!

echo "will shutdown"
apply_gateway
echo "byebye."
exit 0
