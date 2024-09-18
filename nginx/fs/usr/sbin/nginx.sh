#!/usr/bin/bash

set -Eeuo pipefail

if [[ -e /etc/resolv.conf ]]; then
	echo "resolv.conf===================="
	cat /etc/resolv.conf
	echo "==============================="
else
	echo "resolv.conf did not exists ===="
fi

mkdir -p /etc/ACME/nginx

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
	if ! [[ -e "/run/nginx/config/$i" ]]; then
		echo "create /run/nginx/config/$i folder..." >&2
		mkdir -p "/run/nginx/config/$i"
	fi
done

if [[ -e /etc/resolv.conf ]]; then
	SYSTEM_RESOLVERS="$(
		cat /etc/resolv.conf | grep -v '^#' | grep -v '127.0.0.1' | grep nameserver | sed -E 's/^nameserver\s+//g'
	)" || true
else
	SYSTEM_RESOLVERS=""
fi
mapfile -t SYSTEM_RESOLVERS_ARR < <(echo "$SYSTEM_RESOLVERS")
{
	RES=()
	for I in "${SYSTEM_RESOLVERS_ARR[@]}"; do
		if [[ ! $I ]]; then
			continue
		fi
		if [[ $I == *:*:* ]]; then
			RES+=("[$I]")
		else
			RES+=("$I")
		fi
	done

	if [[ ${#RES[@]} -eq 0 ]]; then
		RES=(1.1.1.1 119.29.29.29)
	fi
	echo "resolver ${RES[*]};"
} >/config/conf.d/resolver.conf

cat /usr/sbin/reload-nginx.sh >/run/sockets/nginx.reload.sh

if [[ -e /config/selfsigned.key ]] && [[ -e /config/selfsigned.crt ]]; then
	echo "use exists openssl cert..."
else
	echo "create openssl cert..."
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -batch \
		-keyout "/config/selfsigned.key" \
		-out "/config/selfsigned.crt"
	echo "done..."
fi

if [[ -e /config/dhparam.pem ]]; then
	echo "good, found dhparam.pem"
	if ! grep -qv 'ssl_dhparam ' /etc/nginx/params/ssl_params; then
		echo "ssl_dhparam /config/dhparam.pem;" >>/etc/nginx/params/ssl_params
		echo "ssl_dhparam /config/dhparam.pem;" >>/etc/nginx/params/ssl_params_stream
	fi
elif ! [[ $DISABLE_SSL ]]; then
	echo 'Not using DH parameters file! generate using "openssl dhparam -dsaparam -out /XXX/config/nginx/dhparam.pem 4096"' >&2
fi

if [[ $DISABLE_SSL ]]; then
	sed -i "s#\$DISABLE_SSL#$DISABLE_SSL#g" /usr/bin/remove-ssl
else
	echo '#''!/usr/bin/bash' >/usr/bin/remove-ssl
fi

remove-ssl

if [[ -e /config/conf.d/default_server.conf ]]; then
	echo "using provided default server."
	cat /config/conf.d/default_server.conf >/etc/nginx/conf.d/90-default_server.conf
else
	echo "create builtin default server."
	if ! [[ -e /config/conf.d/default_server.conf.example ]]; then
		echo "create default server example file."
		cat /etc/nginx/conf.d/90-default_server.conf >/config/conf.d/default_server.conf.example
	fi
fi

/usr/sbin/nginx -t || {
	echo "===================================="
	echo "!! Failed test nginx config files !!"
	echo "===================================="
	exit 127
}

sleep 1

bash /usr/sbin/auto-reloader.sh &

echo "[***] running nginx." >&2
exec /usr/sbin/nginx
