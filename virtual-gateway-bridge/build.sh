#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

STEP="安装依赖"
make_base_image_by_dnf "infra-bridge" scripts/requirements.lst

STEP="下载init"
REPO="gongt/init"
get_download() {
	http_get_github_release_id "$REPO"
}
do_download() {
	local URL DOWNLOADED CONTAIENR="$1"
	URL=$(github_release_asset_download_url linux_amd64)
	DOWNLOADED=$(download_file_force "$URL")
	xbuildah copy --chmod 0777 "$CONTAIENR" "$DOWNLOADED" "/sbin/init"
}
buildah_cache2 "infra-bridge" get_download do_download

STEP="下载udp2raw"
REPO="wangyu-/udp2raw-tunnel"
get_download() {
	http_get_github_release_id "$REPO"
}
do_download() {
	local URL DOWNLOADED TMPD
	TMPD=$(create_temp_dir udp2raw)
	URL=$(github_release_asset_download_url udp2raw_binaries.tar.gz)
	DOWNLOADED=$(download_file_force "$URL")
	decompression_file "$DOWNLOADED" 0 "$TMPD"
	buildah copy "$1" "$TMPD/udp2raw_amd64" "/usr/bin/udp2raw_amd64"
}
buildah_cache2 "infra-bridge" get_download do_download

STEP="下载UDPspeeder"
REPO="wangyu-/UDPspeeder"
get_download() {
	http_get_github_release_id "$REPO"
}
do_download() {
	local URL DOWNLOADED TMPD
	TMPD=$(create_temp_dir UDPspeeder)
	URL=$(github_release_asset_download_url speederv2_binaries.tar.gz)
	DOWNLOADED=$(download_file_force "$URL")
	decompression_file "$DOWNLOADED" 0 "$TMPD"
	buildah copy "$1" "$TMPD/speederv2_amd64" "/usr/bin/speederv2_amd64"
}
buildah_cache2 "infra-bridge" get_download do_download

STEP="复制配置文件"
merge_local_fs "infra-bridge"

STEP="配置镜像"
buildah_config "infra-bridge" \
	--cmd "/opt/init.sh" \
	--author "GongT <admin@gongt.me>" \
	--created-by "#MAGIC!" \
	--label name=gongt/virtual-gateway-bridge

RESULT=$(new_container "infra-bridge" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/virtual-gateway-bridge
info "Done!"
