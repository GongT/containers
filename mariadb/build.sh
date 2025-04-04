#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_finish "$@"

### Runtime Base
source ../systemd-base-image/include.sh
image_base
### Runtime Base END

### 依赖项目
STEP="安装系统依赖"
dnf_use_environment
dnf_install_step "mariadb" scripts/deps.lst scripts/clean-install.sh
### 依赖项目 END

merge_local_fs "mariadb"

setup_systemd "mariadb" \
	enable "REQUIRE=mariadb.service backup.timer" "WANT=logrotate.timer" \
	nginx_attach "CONFIG_FILE=/opt/phpmyadmin.conf"

buildah_config "mariadb" \
	--volume /var/lib/mysql --volume /var/log --port 3306 --stop-signal SIGINT \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/mariadb

buildah_finalize_image "mariadb" gongt/mariadb
info "Done!"
