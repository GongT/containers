#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_finish "$@"

buildah_cache_start ghcr.io/bililiverecorder/bililiverecorder

STEP="安装系统依赖"
function hash_deps() {
	cat scripts/install-deps.sh
}
function install_deps() {
	perfer_proxy buildah run $(use_apt_cache liverecord) "$1" bash <scripts/install-deps.sh
}
buildah_cache liverecord hash_deps install_deps

# 安装依赖
STEP="下载init"
REPO=GongT/init
RELEASE_URL=
_hash_init() {
	http_get_github_release_id "$REPO"
	RELEASE_URL=$(github_release_asset_download_url linux_amd64)
}
_download_init() {
	local TGT=$1 DOWNLOADED FILE_NAME="gongt-init"
	DOWNLOADED=$(FORCE_DOWNLOAD=yes download_file "$RELEASE_URL" "$FILE_NAME")
	buildah copy "$TGT" "$DOWNLOADED" "/usr/sbin/init"
	buildah run "$TGT" chmod 0777 "/usr/sbin/init"
}
buildah_cache liverecord _hash_init _download_init
# 安装依赖 END

STEP="复制文件系统"
merge_local_fs liverecord

STEP="更新配置"
buildah_config liverecord --entrypoint '["/bin/bash", "-c"]' --cmd '/entrypoint.sh' \
	--volume=/data/records

buildah_finalize_image "liverecord" gongt/liverecord
