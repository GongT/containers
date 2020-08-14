#!/bin/sh

set -e

if ! [ -e "/data/database.sqlite3" ] ; then
	echo "Now create database"
	# apk add sqlite
	gzip -d -c /opt/init.sql.gz | sqlite3 /data/database.sqlite3
	# apk del sqlite
	echo "Created database"
fi

exec pdns_server
