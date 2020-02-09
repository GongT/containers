#!/bin/sh

set -eu

cd /usr/share/webapps/nextcloud

if ! [[ -e config/.INSTALL ]]; then
	echo "Found nextcloud NOT installed (config/.INSTALL not exists)"
	chown -R root:root config
	sh /opt/install.sh
	touch config/.INSTALL
else
	echo "Found nextcloud installed."
fi

chown -R media_rw:users config /var/lib/nextcloud/apps /var/log/nextcloud

echo 'nameserver 10.0.0.1' > /etc/resolv.conf

exec /usr/sbin/php-fpm7 --nodaemonize --force-stderr --allow-to-run-as-root
