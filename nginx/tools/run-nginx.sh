#!/bin/bash

set -Eeuo pipefail

if ! [[ -e "/etc/letsencrypt/nginx/load.conf" ]]; then
	mkdir -p /etc/letsencrypt/nginx
	echo > "/etc/letsencrypt/nginx/load.conf"
fi


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

exec /usr/sbin/nginx
