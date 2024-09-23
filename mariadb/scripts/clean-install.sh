#!/usr/bin/env bash

set -xEeuo pipefail

rm -rf /etc/nginx /etc/php-fpm.d
mkdir -p /etc/nginx /etc/php-fpm.d

rm -rf /etc/my.cnf.d
