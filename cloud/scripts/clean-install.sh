#!/usr/bin/env bash

set -xEeuo pipefail

mkdir -p /var/log/nginx /var/log/php-fpm
chmod 0777 /var/log/nginx /var/log/php-fpm

rm -rf /etc/nginx /etc/php-fpm.d
mkdir -p /etc/nginx /etc/php-fpm.d
