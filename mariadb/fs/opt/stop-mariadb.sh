#!/bin/sh

echo "Request shutdown server..." >&2
exec mariadb-admin "-p$(< /var/lib/mysql/.password)" shutdown
