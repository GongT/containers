#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_finish "$@"

buildah_cache_start ghcr.io/bililive/bililiverecorder

STEP="安装系统依赖"
function hash_deps() {
	cat scripts/install-deps.sh
}
function install_deps() {
	perfer_proxy buildah run $(use_debian_apt_cache) "$1" bash <scripts/install-deps.sh
}
buildah_cache2 liverecord hash_deps install_deps

STEP="下载init"
REPO=GongT/init
hash_init() {
	http_get_github_release_id "$REPO"
	RELEASE_URL=$(echo "$LAST_GITHUB_RELEASE_JSON" | jq -r '.tarball_url')
}
download_init() {
	local DOWNLOADED FILE_NAME="gongt-init"
	DOWNLOADED=$(FORCE_DOWNLOAD=yes download_file "$RELEASE_URL" "$FILE_NAME")
	buildah copy "$1" "$DOWNLOADED" "/usr/sbin/init"
}
buildah_cache2 liverecord hash_init download_init

STEP="复制文件系统"
merge_local_fs liverecord

STEP="更新配置"
buildah_config liverecord --entrypoint '/entrypoint.sh' --cmd 'init' \
	--volume=-/rec --volume=/data/raw --volume=/data/mp4

RESULT=$(create_if_not "liverecord" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/liverecord
