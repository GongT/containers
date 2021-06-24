#!/usr/bin/bash

set -Eeuo pipefail

if [[ -e /etc/resolv.conf ]]; then
	echo "resolv.conf===================="
	cat /etc/resolv.conf
	echo "==============================="
else
	echo "resolv.conf did not exists ===="
fi

if ! [[ -e "/etc/letsencrypt/nginx/load.conf" ]]; then
	mkdir -p /etc/letsencrypt/nginx
	echo >"/etc/letsencrypt/nginx/load.conf"
fi

erun() {
	echo " + $*" >&2
	"$@"
}
cd /etc/nginx/basic

if [[ $CENSORSHIP ]]; then
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

if [[ -e /etc/resolv.conf ]]; then
	SYSTEM_RESOLVERS="$(cat /etc/resolv.conf | grep -v '127.0.0.1' | grep nameserver | sed -E 's/^nameserver\s+//g')"
else
	SYSTEM_RESOLVERS=""
fi
mapfile -t SYSTEM_RESOLVERS_ARR < <(echo "$SYSTEM_RESOLVERS")
{
	echo -n "resolver "
	for I in "${SYSTEM_RESOLVERS_ARR[@]}"; do
		if [[ $I == *:*:* ]]; then
			echo -n "[$I] "
		else
			echo -n "$I "
		fi
	done
	if [[ ${#SYSTEM_RESOLVERS_ARR[@]} -eq 0 ]]; then
		echo -n "8.8.8.8 223.5.5.5"
	fi
	echo ';'
} >/config.auto/conf.d/resolver.conf

cat /usr/sbin/reload-nginx.sh >/run/sockets/nginx.reload.sh
rm -f /run/sockets/nginx.reload.sock

if [[ -e /config.auto/selfsigned.key ]] && [[ -e /config.auto/selfsigned.crt ]]; then
	echo "use exists openssl cert..."
else
	echo "create openssl cert..."
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -batch \
		-keyout "/config.auto/selfsigned.key" \
		-out "/config.auto/selfsigned.crt"
	echo "done..."
fi

/usr/sbin/nginx -t || {
	echo "===================================="
	echo "!! Failed test nginx config files !!"
	echo "===================================="
	exit 127
}

sleep 1

echo "[***] running nginx." >&2
exec /usr/sbin/nginx
