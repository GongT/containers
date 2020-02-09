#!/bin/sh

apk --no-cache add mariadb mariadb-client bash phpmyadmin php-fpm nginx
mkdir -p /var/lib/nginx/logs/error.log /run/nginx
