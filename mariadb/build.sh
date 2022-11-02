#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

### 依赖
DEPS=(mariadb mariadb-client mariadb-backup bash phpmyadmin php81-fpm nginx p7zip logrotate)
make_base_image_by_apk "registry.gongt.me/gongt/init" "mariadb" "${DEPS[@]}" <scripts/build-script.sh
RESULT=$(create_if_not mariadb-worker registry.gongt.me/gongt/init)
### 依赖 END

merge_local_fs "mariadb"

buildah_config "mariadb" --cmd '/sbin/init' \
	--volume /var/lib/mysql --volume /var/log --port 3306 --stop-signal SIGINT \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/mariadb

RESULT=$(create_if_not "mariadb" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/mariadb
info "Done!"
