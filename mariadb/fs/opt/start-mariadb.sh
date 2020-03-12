#!/bin/bash

set -Eeuo pipefail

sleep 2 # wait for other processes
shopt -s dotglob

if [[ "$(ls /var/lib/mysql | wc -l)" -eq 0 ]]; then
	RAND_PASS=$(echo $RANDOM | md5sum | awk '{print $1}')
	echo "Database did not exists!"
	echo " * create data dir"
	mariadb-install-db --datadir=/var/lib/mysql-temp --user=root
	echo " * start temp server"
	rm -f /var/log/mysqld.err
	ln -sf /dev/stderr /var/log/mysqld.err
	/usr/bin/mysqld --basedir=/usr --datadir=/var/lib/mysql-temp \
		--plugin-dir=/usr/lib/mariadb/plugin --user=root \
		--skip-name-resolve --socket /tmp/install.sock \
		--log-error=/var/log/mysqld.err &
	sleep 5

	echo " * change password"
	mariadb-admin --socket /tmp/install.sock password "$RAND_PASS"
	echo -n "$RAND_PASS" > /var/lib/mysql-temp/.password
	chmod 0600 /var/lib/mysql-temp/.password

	echo " * shutdown temp server"
	mariadb-admin --socket /tmp/install.sock -p"$RAND_PASS" shutdown
	echo " * move data files"
	mv /var/lib/mysql-temp/* /var/lib/mysql/
	echo "Complete init database."
fi

trap "echo 'GOT SIGUSR1, MARIADB SERVER WILL SHUTDOWN.' ; bash /opt/stop-mariadb.sh" USR1 INT

echo "
\$cfg['ProxyUrl'] = '$PROXY';
\$cfg['Servers'][\$i]['password'] = '$(</var/lib/mysql/.password)';
" >> /etc/phpmyadmin/config.inc.php

rm -f /run/sockets/mariadb.sock
/usr/bin/mariadbd --user=root --skip-name-resolve --socket /run/sockets/mariadb.sock &
W=$!
echo "Mariadb is running... PID=$W"

set +e
while true ; do
	wait $W
	RET=$?
	if [[ $RET -eq 138 ]] ; then # errno 138: Interrupt by signal
		continue # must wait for mariadbd to really exit
	elif [[ $? -eq 127 ]]; then
		echo "mariadbd quit with unknown code."
		break # pid not exists, it already quit by some reason
	else
		echo "mariadbd quit with code $RET"
		break
	fi
done
echo "Done."
