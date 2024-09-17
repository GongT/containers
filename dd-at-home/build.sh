#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_finish "$@"

buildah_cache_start "registry.fedoraproject.org/fedora-minimal"

# 安装依赖
REPO=dd-center/DDatHome-go
STEP="下载$REPO"
RELEASE_URL=
_hash_client() {
	http_get_github_release_id "$REPO"
	RELEASE_URL=$(github_release_asset_download_url_regex linux-amd64)
}
_download_client() {
	local TGT=$1 DOWNLOADED=
	DOWNLOADED=$(download_file "$RELEASE_URL" DDatHome.elf)
	buildah copy "$TGT" "$DOWNLOADED" "/opt/DDatHome"
	buildah run "$TGT" chmod 0777 "/opt/DDatHome"
}
buildah_cache ddathome _hash_client _download_client
# 安装依赖 END

STEP="复制文件系统"
merge_local_fs ddathome

STEP="更新配置"
buildah_config ddathome --cmd '/opt/DDatHome'

buildah_finalize_image "ddathome" gongt/dd-at-home
