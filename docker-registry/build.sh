#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_finish

### 依赖项目
STEP="复制gongt/alpine-init"
hash_init() {
	{
		perfer_proxy podman pull -q gongt/alpine-init
		perfer_proxy podman pull -q registry
	} | md5sum
}
download_init() {
	local RESULT MNT SOURCE
	RESULT=$(new_container "$1" "registry")

	SOURCE=$(new_container "temp$RANDOM" "gongt/alpine-init")
	MNT=$(buildah mount "$SOURCE")

	buildah copy "$RESULT" "$MNT/sbin/init" "/sbin/init"
	buildah run $(use_alpine_apk_cache) $RESULT apk add -U libstdc++

	{
		buildah umount "$SOURCE"
		buildah rm "$SOURCE"
	} >/dev/null
}
buildah_cache "docker-registry-copy" hash_init download_init
### 依赖项目 END

info "copy files..."
RESULT=$(new_container registry-worker "$BUILDAH_LAST_IMAGE")

buildah copy "$RESULT" fs /
buildah config --cmd '/sbin/init' --stop-signal=SIGINT "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/docker-registry "$RESULT"

buildah commit "$RESULT" gongt/docker-registry
info "Done!"
