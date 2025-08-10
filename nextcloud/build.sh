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
STEP="安装nextcloud依赖"
dnf_use_environment
dnf_install_step "nextcloud" scripts/deps.lst scripts/clean-install.sh
### 依赖项目 END

STEP="复制配置文件"
merge_local_fs "nextcloud"

setup_systemd "nextcloud" \
	enable "REQUIRE=nginx.service php-fpm.service redis.service nextcloud-clean.timer" \
	nginx_attach "CONFIG_FILE=/opt/nextcloud.conf"

buildah_config "nextcloud" \
	--author "GongT <admin@gongt.me>" \
	--created-by "#MAGIC!!" \
	--label name=gongt/nextcloud

buildah_finalize_image "nextcloud" gongt/nextcloud
