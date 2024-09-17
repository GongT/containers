#!/usr/bin/env bash

set -Eeuo pipefail

mkdir -p /var/log/nginx /var/log/php-fpm
chmod 0777 /var/log/nginx /var/log/php-fpm

rm -rf /etc/nginx /etc/php-fpm.d
mkdir -p /etc/nginx /etc/php-fpm.d

if id nextcloud 2>/dev/null; then
	userdel nextcloud
fi

groupadd --force --gid 100 users
useradd --no-create-home --home-dir /var/lib/nextcloud --shell /sbin/nologin --no-user-group --gid users --uid 100 media_rw

chown 100:100 /var/lib/nextcloud -R
