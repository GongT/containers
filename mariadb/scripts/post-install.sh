#!/usr/bin/env bash

set -Eeuo pipefail

systemctl enable nginx.service mariadb.service logrotate.timer php-fpm.service

echo "NGINX_CONFIG=/opt/phpmyadmin.conf" >> /etc/environment
echo "MYSQLD_OPTS=--skip-name-resolve --socket /run/sockets/mariadb.sock" >> /etc/environment
