#!/bin/bash

set -eu

cd /usr/share/nextcloud

if ! [[ -e config/.INSTALL ]]; then
	echo "Found nextcloud NOT installed ($(pwd)/config/.INSTALL not exists)"
	chown -R root:root config
	sh /opt/install.sh
	touch config/.INSTALL
else
	echo "Found nextcloud installed."
fi

cp -vu /opt/auto.config.php config/auto.config.php

chown -R media_rw:users config /var/lib/nextcloud/apps /var/log/nextcloud
