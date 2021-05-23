#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

### 准备容器
STEP="准备容器"
make_base_image_by_apk "ethereum/client-go:stable" "eth-build" "bash"

### 复制文件
STEP="复制文件"
hash_fs_files() {
	hash_path fs
}
copy_fs_files() {
	buildah copy "$1" fs /
}
buildah_cache2 "eth-build" hash_fs_files copy_fs_files
### 复制文件 END

info_log ""

RESULT=$(new_container "btc-final" "$BUILDAH_LAST_IMAGE")
buildah_config "$RESULT" '--cmd=/opt/start.sh' --port 30303 \
	--entrypoint '["/bin/bash"]' \
	--author "GongT <admin@gongt.me>" \
	--created-by "#MAGIC!" \
	--label name=gongt/ethereum-peer

RESULT=$(create_if_not "ethereum" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/ethereum-peer
info "Done!"
