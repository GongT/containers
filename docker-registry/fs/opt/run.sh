#!/bin/sh

PROJ=docker-registry

apply_gateway() {
	F=$1 T="/run/nginx/config/vhost.d/${PROJ}.conf"
	if [ -z "$F" ]; then
		rm -v "${T}"
	else
		cp -v "/opt/${F}.conf" "${T}"
	fi
	echo 'GET /' | nc local:/run/nginx/sockets/nginx.reload.sock
}
trap 'echo "got SIGINT"' INT

echo "GC...."
registry garbage-collect /etc/docker/registry/config.yml --delete-untagged

echo "reload nginx..."
apply_gateway docker-registry

echo "starting...."
/entrypoint.sh /etc/docker/registry/config.yml &
wait $!

echo "will shutdown"
apply_gateway
echo "byebye."
exit 0
