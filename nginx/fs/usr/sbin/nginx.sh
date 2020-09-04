#!/bin/bash

set -Eeuo pipefail

echo "resolv.conf===================="
echo "$(< /etc/resolv.conf)"
echo "==============================="

if ! [[ -e "/etc/letsencrypt/nginx/load.conf" ]]; then
	mkdir -p /etc/letsencrypt/nginx
	echo > "/etc/letsencrypt/nginx/load.conf"
fi

erun() {
	echo " + $*" >&2
	"$@"
}
cd /etc/nginx/basic
if [[ -n "$CENSORSHIP" ]]; then
	for i in *.conf; do
		erun sed -i 's#$out_port_https#:59443#g' "$i"
	done
else
	for i in *.conf; do
		erun sed -i 's#$out_port_https##g; s/listen 59/# listen 59/g' "$i"
	done
fi

if [[ -e "/config/htpasswd" ]]; then
	rm -f "/config/htpasswd"
fi
echo "create htpassword file..." >&2
htpasswd -bc "/config/htpasswd" "$USERNAME" "$PASSWORD"

for i in conf.d vhost.d stream.d rtmp.d; do
	if ! [[ -e "/config/$i" ]]; then
		echo "create /config/$i folder..." >&2
		mkdir -p "/config/$i"
	fi
	if ! [[ -e "/config.auto/$i" ]]; then
		echo "create /config.auto/$i folder..." >&2
		mkdir -p "/config.auto/$i"
	fi
done

SYSTEM_RESOLVERS=$(cat /etc/resolv.conf | grep -v '127.0.0.1' | grep nameserver | sed -E 's/^nameserver\s+//g')
if [[ -z "$SYSTEM_RESOLVERS" ]]; then
	SYSTEM_RESOLVERS="8.8.8.8"
fi
echo "resolver $SYSTEM_RESOLVERS;" > /config.auto/conf.d/resolver.conf

cat /usr/sbin/reload-nginx.sh > /run/sockets/nginx.reload.sh
rm -f /run/sockets/nginx.reload.sock

/usr/sbin/nginx -t || {
	echo "===================================="
	echo "!! Failed test nginx config files !!"
	echo "===================================="
	exit 127
}

sleep 1

echo "[***] running nginx." >&2
exec /usr/sbin/nginx
