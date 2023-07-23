#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

buildah_cache_start "archlinux:latest"

### 依赖项目
STEP="安装系统依赖"
DEPS=(curl iperf3 systemd)
pacman_hash() {
	echo "${DEPS[*]}"
}
pacman_install() {
	buildah run $(use_pacman_cache) "$1" "bash" "-c" "pacman --noconfirm -S ${DEPS[*]}"
}
buildah_cache2 "infra-build" pacman_hash pacman_install
### 依赖项目 END

### 配置文件等
STEP="复制配置文件"
merge_local_fs "infra-build"
### 配置文件等 END

setup_systemd "infra-build"

buildah_cache_run "infra-build" scripts/prepare-env.sh

buildah_config "infra-build" --author "GongT <admin@gongt.me>" --label name=gongt/virtual-gateway
info "settings update..."

RESULT=$(create_if_not "infra-result" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/virtual-gateway
info "Done!"
