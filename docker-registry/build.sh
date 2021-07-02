#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_finish

### 依赖
STEP="安装依赖"
make_base_image_by_apk "docker.io/registry" "docker-registry" libstdc++
### 依赖 END

### sbin/init
STEP="复制gongt/alpine-init"
hash_init() {
	perfer_proxy podman pull gongt/alpine-init
}
download_init() {
	local RESULT="$1"
	buildah copy "--from=gongt/alpine-init" "$RESULT" "/sbin/init" "/sbin/init"
}
buildah_cache2 "docker-registry" hash_init download_init
### sbin/init END

info "copy files..."

merge_local_fs "docker-registry"

buildah_config "docker-registry" --cmd '/sbin/init' --stop-signal=SIGINT \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/docker-registry

RESULT=$(create_if_not registry-worker "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/docker-registry
info "Done!"
