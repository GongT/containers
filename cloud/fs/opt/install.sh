#!/bin/sh

set -eu
cd /usr/share/webapps/nextcloud

echo 'nameserver 10.0.0.1' > /resolv.conf

echo_run() {
	echo "$*"
	"$@"
}

echo "Run merge config file ..."
echo "<?php
file_put_contents('config/config.php',
	'<?php 
	\$CONFIG = ' . var_export(
		array_merge(require('/opt/config.default.php'),
		array(
			'mail_smtppassword' => '$SMTP_PASSWORD',
			'proxy' => '$PROXY',
		)
	), true)
. ';

');

" | php

touch config/CAN_INSTALL 

# echo "Run maintenance:install ..."
echo_run php -d memory_limit=2G occ maintenance:install \
	--database=mysql \
	--database-name=nextcloud \
	--database-host= \
	--database-port=/run/sockets/mariadb.sock \
	--database-user=nextcloud \
	--database-pass=nextcloud \
	--database-table-prefix= \
	--admin-user=nextcloud \
	"--admin-pass=nextcloud" \
	--admin-email=admin@gongt.me \
	--data-dir=/data \
	--no-ansi --no-interaction -vv

echo "Install complete."
