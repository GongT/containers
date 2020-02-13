#!/bin/sh

PROJ=test-hexo

apply_gateway() {
	local F=$1 T="/run/nginx/vhost.d/${PROJ}.conf"
	if [ -z "$F" ] ; then
		rm -v "${T}"
	else
		cp -v "/opt/${F}.conf" "${T}"
	fi
	echo 'GET /' | nc local:/run/sockets/nginx.reload.sock
}

apply_gateway hexo

trap 'echo "got SIGINT"' INT

echo "starting...."

if ! [ -e /etc/hexo/config.yml ]; then
	echo " >> create /etc/hexo"
	mkdir -p /etc/hexo
	echo " >> create /etc/hexo/config.yml"
	echo 'title: Your site title
' > /etc/hexo/config.yml
fi
if ! [ -e /etc/hexo/admin-config.yml ]; then
	touch /etc/hexo/admin-config.yml
fi

erun() {
	echo "$*"
	"$@"
}

cd /data
erun ./node_modules/.bin/hexo generate
erun ./node_modules/.bin/hexo serve --config /data/_config.yml,/etc/hexo/config.yml,/opt/config.force.yml -p 22153 -i 127.0.0.1 &
wait $!

echo "will shutdown"

apply_gateway

echo "byebye."
exit 0
