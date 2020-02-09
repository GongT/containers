#!/bin/bash

set -Eeuo pipefail

echo 'nameserver 10.0.0.1' > /etc/resolv.conf

sleep 10 # wait for other processes

if [[ "$(ls /var/lib/mysql | wc -l)" -eq 0 ]]; then
	RAND_PASS=$(echo $RANDOM | md5sum | awk '{print $1}')
	echo "Database did not exists!"
	echo " * create data dir"
	mariadb-install-db --datadir=/var/lib/mysql-temp --user=root
	echo " * start temp server"
	rm -f /var/log/mysqld.err
	ln -sf /dev/stderr /var/log/mysqld.err
	/usr/bin/mariadbd-safe --user=root --skip-name-resolve --socket /tmp/install.sock --datadir /var/lib/mysql-temp &
	sleep 5

	echo " * change password"
	mariadb-admin --socket /tmp/install.sock password "$RAND_PASS"
	echo -n "$RAND_PASS" > /var/lib/mysql/.password
	chmod 0600 /var/lib/mysql/.password

	echo " * shutdown temp server"
	mariadb-admin --socket /tmp/install.sock -p"$RAND_PASS" shutdown
	echo " * move data files"
	mv /var/lib/mysql-temp/* /var/lib/mysql/
	echo "Complete init database."
fi

trap "echo 'GOT SIGUSR1, MARIADB SERVER WILL SHUTDOWN.' ; bash /opt/stop-mariadb.sh" USR1

echo "
\$cfg['ProxyUrl'] = '$PROXY';
\$cfg['Servers'][\$i]['password'] = '$(</var/lib/mysql/.password)';
" >> /etc/phpmyadmin/config.inc.php

rm -f /run/sockets/mariadb.sock
/usr/bin/mariadbd --user=root --skip-name-resolve --socket /run/sockets/mariadb.sock &
W=$!

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
