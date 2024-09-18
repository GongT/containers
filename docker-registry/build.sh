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
STEP="复制registry.gongt.me/gongt/init"
hash_init() {
	perfer_proxy podman pull registry.gongt.me/gongt/init
}
download_init() {
	local RESULT="$1"
	buildah copy "--from=registry.gongt.me/gongt/init" "$RESULT" "/sbin/init" "/sbin/init"
}
buildah_cache "docker-registry" hash_init download_init
### sbin/init END

info "copy files..."

merge_local_fs "docker-registry"

buildah_config "docker-registry" --cmd '/sbin/init' --stop-signal=SIGINT \
	"--env=REGISTRY_HTTP_ADDR=/run/sockets/docker-registry.sock" \
	"--env=REGISTRY_HTTP_NET=unix" \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/docker-registry

buildah_finalize_image docker-registry gongt/docker-registry
info "Done!"
