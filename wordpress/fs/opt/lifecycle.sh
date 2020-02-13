#!/bin/sh

PROJ=wordpress

apply_gateway() {
	local F=$1 T="/run/nginx/vhost.d/${PROJ}.conf"
	if [ -z "$F" ] ; then
		rm -v "${T}"
	else
		cp -v "/opt/${F}.conf" "${T}"
	fi
	echo 'GET /' | nc local:/run/sockets/nginx.reload.sock
}

if nslookup z.cn 127.0.0.53 &>/dev/null ; then
	echo 'nameserver 127.0.0.53' > /etc/resolv.conf
else
	echo 'nameserver 10.0.0.1' > /etc/resolv.conf
fi

apply_gateway bridge

trap 'echo "will shutdown"' INT

echo "sleep."
sleep infinity &
wait $!

echo "wakeup."

rm -vf /run/sockets/word-press.sock

apply_gateway

echo "byebye."
