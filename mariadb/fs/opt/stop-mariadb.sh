#!/bin/sh

set -e

echo "Request shutdown server..." >&2
PASWD=$(cat /var/lib/mysql/.password)

set -x
exec mariadb-admin "-p$PASWD" shutdown
