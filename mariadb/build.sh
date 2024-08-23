#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."
buildah_cache_start "fedora:$FEDORA_VERSION"

### 依赖项目
STEP="安装系统依赖"
POST_SCRIPT=$(<scripts/clean-install.sh) \
	dnf_install "mariadb" scripts/deps.lst
### 依赖项目 END

setup_systemd "mariadb" nginx_attach

merge_local_fs "mariadb" scripts/post-install.sh

buildah_config "mariadb" \
	--volume /var/lib/mysql --volume /var/log --port 3306 --stop-signal SIGINT \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/mariadb

RESULT=$(create_if_not "mariadb" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/mariadb
info "Done!"
