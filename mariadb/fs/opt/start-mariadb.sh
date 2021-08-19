#!/bin/bash

set -Eeuo pipefail

sleep 2 # wait for other processes
shopt -s dotglob

function write_password_cfg() {
	echo " * write password config"
	local PWD_FILE="$1"
	if ! [[ -f $PWD_FILE ]]; then
		echo "Fatal: no .password file, maybe external data dir, you need create it." >&2
		exit 233
	fi
	echo "[client]
	password = $(<"$PWD_FILE")
" >/etc/my.cnf.d/98-password.cnf

	{
		if [[ "${PROXY:-}" ]]; then
			echo "\$cfg['ProxyUrl'] = '$PROXY';"
		fi
		echo "\$cfg['Servers'][\$i]['password'] = '$(<"$PWD_FILE")';"
	} >>/etc/phpmyadmin/config.inc.php
}

if [[ "$(ls /var/lib/mysql | wc -l)" -eq 0 ]]; then
	RAND_PASS=$(echo $RANDOM | md5sum | awk '{print $1}')
	echo "Database did not exists!"

	mkdir -p /backup/automatic
	if [[ "$(ls /backup/automatic | wc -l)" -ne 0 ]]; then
		die "datadir empty, and backup exists, to restore data, see: https://mariadb.com/kb/en/incremental-backup-and-restore-with-mariabackup/#preparing-the-backup"
	fi

	echo " * create data dir"
	mariadb-install-db --datadir=/var/lib/mysql-temp --user=root
	echo " * start temp server"
	rm -f /var/log/mysqld.err
	ln -sf /dev/stderr /var/log/mysqld.err
	echo -e "[mysqld]\ndatadir = /var/lib/mysql-temp" >/etc/my.cnf.d/99-data-dir-temp.cnf
	/usr/bin/mysqld --basedir=/usr --datadir=/var/lib/mysql-temp \
		--plugin-dir=/usr/lib/mariadb/plugin --user=root \
		--skip-name-resolve --socket /tmp/install.sock \
		--log-error=/var/log/mysqld.err &
	sleep 5
	rm -f /etc/my.cnf.d/99-data-dir-temp.cnf

	echo " * change password"
	mariadb-admin --socket /tmp/install.sock password "$RAND_PASS"
	echo -n "$RAND_PASS" >/var/lib/mysql-temp/.password
	chmod 0600 /var/lib/mysql-temp/.password

	write_password_cfg /var/lib/mysql-temp/.password
	echo " *     phpmyadmin database init"
	{
		cat /usr/share/webapps/phpmyadmin/sql/create_tables.sql
		cat /opt/init.sql
	} | mysql --socket /tmp/install.sock
	echo "           -> ok"

	echo " * shutdown temp server"
	mariadb-admin --socket /tmp/install.sock -p"$RAND_PASS" shutdown
	echo " * move data files"
	mv /var/lib/mysql-temp/* /var/lib/mysql/
	echo "Complete init database."
else
	write_password_cfg /var/lib/mysql/.password
fi

trap "echo 'GOT SIGUSR1, MARIADB SERVER WILL SHUTDOWN.' ; bash /opt/stop-mariadb.sh" USR1 INT

/usr/bin/mariadbd --user=root --skip-name-resolve --socket /run/sockets/mariadb.sock &
W=$!
echo "Mariadb is running... PID=$W"

set +e
while true; do
	wait $W
	RET=$?
	if [[ $RET -eq 138 ]]; then # errno 138: Interrupt by signal
		continue                   # must wait for mariadbd to really exit
	elif [[ $? -eq 127 ]]; then
		echo "mariadbd quit with unknown code."
		break # pid not exists, it already quit by some reason
	else
		echo "mariadbd quit with code $RET"
		break
	fi
done
echo "Done."
