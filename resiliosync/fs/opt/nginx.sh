#!/usr/bin/env bash

set -Eeuo pipefail

apply_gateway() {
	F=${1:-} T="/run/nginx/vhost.d/ResilioSync.$PROFILE.conf"
	if [ -z "$F" ]; then
		if [[ -e $T ]]; then
			rm -vf "${T}"
		fi
	else
		sed "s#__PROFILE__#$PROFILE#g" "/opt/${F}.conf" >"${T}"
	fi
	echo 'GET /' | ncat --unixsock /run/sockets/nginx.reload.sock
}
trap 'echo "got SIGINT"' INT

echo "reload nginx..."
apply_gateway nginx

function do_stop() {
	echo "stop signal"
	apply_gateway || true
	echo "byebye."
	exit 0
}
trap do_stop INT

echo "starting...."
rm -f /run/sockets/resiliosync.$PROFILE.sock
mkdir -p /var/log/nginx/
sed -i "s#__PROFILE__#$PROFILE#g" /etc/nginx/nginx.conf
sed -i "s#__PORT__#$UIPORT#g" /etc/nginx/pass.conf
nginx -t
nginx &
wait $!
