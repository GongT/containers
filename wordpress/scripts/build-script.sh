#!/bin/sh

set -e

apk add -U nginx redis php7 php-fpm curl memcached \
	php7-pecl-xdebug php7-pecl-apcu php7-opcache php7-curl \
	php7-pecl-gmagick php7-pecl-imagick php7-gd php7-gd php7-mbstring \
	php7-xmlreader php7-xml php7-exif php7-iconv php7-json \
	php7-sockets php7-tokenizer php7-pecl-memcached php7-pecl-igbinary \
	php7-json php7-mysqli php7-simplexml php7-openssl php7-posix

mkdir -p /var/lib/nginx/logs /run/nginx
mkdir -p /project
