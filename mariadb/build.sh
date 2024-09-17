#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."
buildah_cache_start "registry.fedoraproject.org/fedora-minimal"

### 依赖项目
STEP="安装系统依赖"
dnf_use_environment
dnf_install_step "mariadb" scripts/deps.lst scripts/clean-install.sh
### 依赖项目 END

setup_systemd "mariadb" \
	enable "UNITS=mariadb.service logrotate.timer nginx.service php-fpm.service backup.timer" \
	nginx_attach "NGINX_CONFIG=/opt/phpmyadmin.conf"

merge_local_fs "mariadb"

buildah_config "mariadb" \
	--volume /var/lib/mysql --volume /var/log --port 3306 --stop-signal SIGINT \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/mariadb

buildah_finalize_image "mariadb" gongt/mariadb
info "Done!"
