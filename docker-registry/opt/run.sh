#!/bin/sh

PROJ=docker-registry

apply_gateway() {
	local F=$1 T="/run/nginx/vhost.d/${PROJ}.conf"
	if [ -z "$F" ] ; then
		rm -v "${T}"
	else
		cp -v "/opt/${F}.conf" "${T}"
	fi
	echo 'GET /' | nc local:/run/sockets/nginx.reload.sock
}
trap 'echo "got SIGINT"' INT

apply_gateway docker-registry

echo "starting...."
/entrypoint.sh /etc/docker/registry/config.yml &
wait $!

echo "will shutdown"
apply_gateway
echo "byebye."
exit 0
