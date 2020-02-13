#!/bin/sh

set -e

apk --no-cache add nginx redis php-fpm curl memcached \
	php7-pecl-xdebug php7-pecl-apcu php7-opcache \
	php7-json php7-mysqli php7-simplexml
	

mkdir -p /var/lib/nginx/logs /run/nginx
mkdir -p /project
