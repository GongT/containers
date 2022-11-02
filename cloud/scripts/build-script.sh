#!/usr/bin/env bash

set -Eeuo pipefail

if id nextcloud 2>/dev/null; then
	userdel nextcloud
fi

groupadd --force --gid 100 users
useradd --no-create-home --home-dir /var/lib/nextcloud --shell /sbin/nologin --no-user-group --gid users --uid 100 media_rw

chown 100:100 /var/lib/nextcloud -R

systemctl enable nginx.service php-fpm.service redis.service nextcloud-clean.timer
