#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

buildah_cache_start "registry.fedoraproject.org/fedora-minimal"

### 依赖项目
STEP="安装系统依赖"
dnf_use_environment
dnf_install_step "nextcloud" scripts/deps.lst scripts/clean-install.sh
### 依赖项目 END

merge_local_fs "nextcloud"

setup_systemd "nextcloud" \
	enable "REQUIRE=nginx.service php-fpm.service nextcloud-clean.timer redis.service" \
	nginx_attach "NGINX_CONFIG="

buildah_config "nextcloud" \
	--author "GongT <admin@gongt.me>" \
	--created-by "#MAGIC!!" \
	--label name=gongt/cloud

buildah_finalize_image "cloud" gongt/cloud
