#!/bin/bash

set -Eeuo pipefail

if ! [[ -e "/etc/letsencrypt/nginx/load.conf" ]]; then
    mkdir -p /etc/letsencrypt/nginx
    echo > "/etc/letsencrypt/nginx/load.conf"
fi

if [[ -n "$CENSORSHIP" ]] ; then
    out_port_http="59080"
    out_port_https="59443"
else
    out_port_http="80"
    out_port_https="443"
fi
cd /etc/nginx/basic
for i in *.conf ; do
    sed -i "s#\$out_port_https#$out_port_https#g; s#\$out_port_http#$out_port_http#g" "$i"
done

if [[ -e "/config/htpasswd" ]]; then
    rm -f "/config/htpasswd"
fi
echo "create htpassword file..." >&2
htpasswd -bc "/config/htpasswd" "$USERNAME" "$PASSWORD"

for i in vhost.d stream.d rtmp.d ; do
    if ! [[ -e "/config/$i" ]]; then
        echo "create $i folder..." >&2
        mkdir -p "/config/$i"
    fi
done

echo "[***] running nginx." >&2

rm -f /run/sockets/nginx.reload.sock
exec /usr/sbin/nginx
