#!/usr/bin/env bash

declare -r PHP_VERSION="81"

CACHE_NAME=$1
shift

PHP_TO_INSTALL=("php$PHP_VERSION")

plugin() {
	local N=$1
	PHP_TO_INSTALL+=("php${PHP_VERSION}-$N")
}
plugin fpm
plugin pecl-xdebug
for I; do
	plugin "$I"
done
unset plugin

STEP="安装php和插件"
make_base_image_by_apk "alpine:edge" "$CACHE_NAME" "${PHP_TO_INSTALL[@]}"
