#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

### 依赖项目
STEP="安装系统依赖"
POST_SCRIPT=$(<scripts/clean-install.sh) \
	make_base_image_by_dnf "nextcloud" scripts/deps.lst
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
buildah_cache2 "nextcloud" hash_install_script run_install_script

STEP="配置镜像"
buildah_config "nextcloud" \
	--author "GongT <admin@gongt.me>" \
	--created-by "#MAGIC!!" \
	--label name=gongt/cloud

info "settings updated..."

RESULT=$(create_if_not "cloud" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/cloud
info "Done!"
