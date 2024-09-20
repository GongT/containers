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
		erun sed -i 's#$out_port_https##g' "$i"
	done
fi

if [[ -e "/config/htpasswd" ]]; then
	rm -f "/config/htpasswd"
fi
echo "create htpassword file..." >&2
htpasswd -bc "/config/htpasswd" "$USERNAME" "$PASSWORD"

if [[ -e /etc/resolv.conf ]]; then
	SYSTEM_RESOLVERS="$(
		cat /etc/resolv.conf | grep -v '^#' | grep -v '127.0.0.1' | grep nameserver | sed -E 's/^nameserver\s+//g'
	)" || true
else
	SYSTEM_RESOLVERS=""
fi
mapfile -t SYSTEM_RESOLVERS_ARR < <(echo "$SYSTEM_RESOLVERS")
(
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
) >/config/conf.d/resolver.conf

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
	if ! grep -q '^ssl_dhparam ' /etc/nginx/params/ssl_params; then
		echo "ssl_dhparam /config/dhparam.pem;" >>/etc/nginx/params/ssl_params
		echo "ssl_dhparam /config/dhparam.pem;" >>/etc/nginx/params/ssl_params_stream
	fi
elif ! [[ $DISABLE_SSL ]]; then
	echo 'Not using DH parameters file!
download one using: 
	curl https://ssl-config.mozilla.org/ffdhe2048.txt > /XXX/config/nginx/dhparam.pem

' >&2
fi

if [[ $DISABLE_SSL ]]; then
	sed -i "s#\$DISABLE_SSL#$DISABLE_SSL#g" /usr/bin/ensure-sslcfg
else
	echo '#''!/usr/bin/bash' >/usr/bin/ensure-sslcfg
fi

ensure-sslcfg || true

if [[ -e /config/conf.d/default_server.conf ]]; then
	echo "using provided default server."
	cat /config/conf.d/default_server.conf >/etc/nginx/conf.d/90-default_server.conf
else
	echo "use builtin default server."
	if ! [[ -e /config/conf.d/default_server.conf.example ]]; then
		echo "create default server example file."
		cat /etc/nginx/conf.d/90-default_server.conf >/config/conf.d/default_server.conf.example
	fi
fi

for FILE in /etc/nginx/basic/listen.conf /etc/nginx/conf.d/90-default_server.conf; do
	if grep -qF SED_THEM_WITH_IPV6 "${FILE}"; then
		DATA=$(sed -E '/SED_THEM_WITH_IPV6/d; /^\s*listen ([[:digit:]]+) /{p; s/listen /listen [::]:/}' "${FILE}")
		echo "$DATA" >"${FILE}"
		unset DATA
	fi
done

for i in conf.d vhost.d stream.d rtmp.d; do
	if ! [[ -e "/config/$i" ]]; then
		echo "create /config/$i folder..." >&2
		mkdir -p "/config/$i"
	fi
done
declare -xr EFFECTIVE_DIR="/run/nginx/config"
mkdir -p "${EFFECTIVE_DIR}"
if [[ ! -L /etc/nginx/effective ]]; then
	ln -s "${EFFECTIVE_DIR}" /etc/nginx/effective
fi

/usr/sbin/nginx -t || {
	echo "===================================="
	echo "!! Failed test nginx config files !!"
	echo "===================================="
	exit 127
}

sleep 1

bash /opt/reload-server.sh &

exec /usr/sbin/nginx
