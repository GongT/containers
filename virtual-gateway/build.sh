#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

### 依赖项目
STEP="安装系统依赖"
DEPS=(bash curl util-linux iproute2)
apk_hash() {
	{
		cat scripts/install.sh
		echo "${DEPS[*]} dhclient"
	} | md5sum
}
apk_install() {
	local CONTAINER
	CONTAINER=$(new_container "$1" "gongt/alpine-init")
	buildah run $(use_alpine_apk_cache) "$CONTAINER" sh -s- -- "${DEPS[@]}" <scripts/install.sh
}
buildah_cache "infra-build" apk_hash apk_install
### 依赖项目 END

### 配置文件等
STEP="复制配置文件"
merge_local_fs "infra-build"
### 配置文件等 END

buildah_config "infra-build" --author "GongT <admin@gongt.me>" --label name=gongt/virtual-gateway
info "settings update..."

RESULT=$(create_if_not "infra-result" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/virtual-gateway
info "Done!"
