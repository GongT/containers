#!/bin/sh

rm -f /run/sockets/php-my-admin.sock

if [ -e /run/sockets/nginx.reload.sh ]; then
	cp /opt/phpmyadmin.conf /run/nginx/vhost.d/phpmyadmin.conf
	sh /run/sockets/nginx.reload.sh
fi

nginx &
PID=$!
echo "nginx is start: $PID"

trap "echo 'RECEIVE SIGINT' ; nginx -s stop" SIGINT

wait $PID
echo "nginx is quit"


if [ -e /run/sockets/nginx.reload.sh ]; then
	rm -f /run/nginx/vhost.d/phpmyadmin.conf
	sh /run/sockets/nginx.reload.sh
fi

rm -f /run/sockets/php-my-admin.sock
