#!/usr/bin/env bash

set -Eeuo pipefail

export RABBITMQ_PID_FILE=/run/rmq.pid

{
	echo
	echo "127.0.0.1 $HOSTNAME"
	echo "::1 $HOSTNAME"
} >>/etc/hosts

if [[ "$NO_SSL" ]]; then
	echo "SSL disabled!" >&2
	rm -f /etc/rabbitmq/rabbitmq.conf
	mv /etc/rabbitmq/rabbitmq.unsafe.conf /etc/rabbitmq/rabbitmq.conf
fi

rm -f /run/sockets/rabbitmq-management.sock
socat "UNIX-LISTEN:/run/sockets/rabbitmq-management.sock,fork" "TCP-CONNECT:127.0.0.1:15672" &

echo "starting..." >&2
rabbitmq-server &

echo "waiting..." >&2
rabbitmqctl wait "$RABBITMQ_PID_FILE" --timeout 20

echo "Startup complete!"
echo "PID=$(<"$RABBITMQ_PID_FILE")"

cp /opt/nginx-server.conf /etc/nginx/vhost.d/rabbitmq-management.conf
bash /run/sockets/.reload/request.sh

function quitfn() {
	rm -f /etc/nginx/vhost.d/rabbitmq-management.conf
	bash /run/sockets/.reload/request.sh
	rm -f /run/sockets/rabbitmq-management.sock
	rabbitmqctl shutdown
}

trap quitfn INT USR1
while :; do
	sleep infinity &
	wait $!
	echo "sleep quit!"
	quitfn
	exit 0
done
