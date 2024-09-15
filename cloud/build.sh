#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

buildah_cache_start "fedora-minimal"

### 依赖项目
STEP="安装系统依赖"
dnf_use_environment
dnf_install_step "nextcloud" scripts/deps.lst scripts/clean-install.sh
### 依赖项目 END

setup_systemd "nextcloud"

merge_local_fs "nextcloud"
info "copy config files complete..."

STEP="安装"
function hash_install_script() {
	hash_path scripts/build-script.sh
}
function run_install_script() {
	buildah run "--volume=$(pwd)/scripts/build-script.sh:/tmp/build-script" "$1" bash '/tmp/build-script'
}
buildah_cache "nextcloud" hash_install_script run_install_script

STEP="配置镜像"
buildah_config "nextcloud" \
	--author "GongT <admin@gongt.me>" \
	--created-by "#MAGIC!!" \
	--label name=gongt/cloud

info "settings updated..."

buildah_finalize_image "cloud" gongt/cloud
info "Done!"
