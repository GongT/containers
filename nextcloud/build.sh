#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

buildah_cache_start "ghcr.io/gongt/systemd-base-image"

### 依赖项目
STEP="安装系统依赖"
dnf_use_environment
dnf_install_step "nextcloud" scripts/deps.lst scripts/clean-install.sh
### 依赖项目 END

merge_local_fs "nextcloud"

setup_systemd "nextcloud" \
	enable "REQUIRE=nginx.service php-fpm.service redis.service nextcloud-clean.timer" \
	nginx_attach "CONFIG_FILE=/opt/nextcloud.conf"

buildah_config "nextcloud" \
	--author "GongT <admin@gongt.me>" \
	--created-by "#MAGIC!!" \
	--label name=gongt/cloud

buildah_finalize_image "cloud" gongt/cloud
