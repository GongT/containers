#!/bin/sh

apk --no-cache add mariadb mariadb-client bash phpmyadmin php-fpm nginx p7zip
rm -rf /etc/nginx
mkdir -p /var/lib/nginx/logs /run/nginx
