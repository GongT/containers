#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_finish "$@"

### Runtime Base
source ../systemd-base-image/include.sh
image_base graphical
### Runtime Base END

dnf_install_step "qqbot" scripts/requirements.lst

### 安装QQNT
STEP=安装QQNT
## curl 'https://im.qq.com/linuxqq/index.shtml' | grep linuxQQDownload
# rainbowConfigUrl="https://cdn-go.cn/qq-web/im.qq.com_new/latest/rainbow/linuxQQDownload.js"
QQNT_DOWNLOAD_URL="https://dldir1.qq.com/qqfile/qq/QQNT/2b82dc28/linuxqq_3.2.12-26909_x86_64.rpm" # this is example
hash_qqnt() {
	# QQNT_DOWNLOAD_URL=$(curl -sL "$rainbowConfigUrl" \
	# 	| grep -oP '"rpm"\s*:\s*".+?"' \
	# 	| grep -F x86 \
	# 	| grep -oE 'http.+\.rpm')
	info_note " * download url: $QQNT_DOWNLOAD_URL"
	control_ci summary "## QQNT
* $(echo "${QQNT_DOWNLOAD_URL#*_}" | sed -e 's#_x86_64\.rpm$##')
* ${QQNT_DOWNLOAD_URL}
"
	echo "${QQNT_DOWNLOAD_URL}"
}
download_qqnt() {
	local CONTAINER="$1" TMPF
	TMPF=$(create_temp_file)
	echo "${QQNT_DOWNLOAD_URL}" >"${TMPF}"
	call_dnf_install "$1" "${TMPF}"
}
buildah_cache "qqbot" hash_qqnt download_qqnt
### 安装QQNT END

STEP=安装LiteLoaderQQNT和插件
RELEASE_URL=
PLUGINS_URL=()
check_LiteLoaderQQNT() {
	http_get_github_release_id "LiteLoaderQQNT/LiteLoaderQQNT"
	RELEASE_URL=$(github_release_asset_download_url LiteLoaderQQNT.zip)
	info_note " * RELEASE_URL=$RELEASE_URL"

	http_get_github_release_id "ltxhhz/LL-plugin-list-viewer"
	PLUGINS_URL+=("$(github_release_asset_download_url list-viewer.zip)")

	# http_get_github_release_id "NapNeko/NapCatQQ"
	# PLUGINS_URL+=("$(github_release_asset_download_url NapCat.Framework.zip)")
}
download_LiteLoaderQQNT() {
	local DOWNLOADED SOURCE_DIRECTORY TMPD PLUGIN
	DOWNLOADED=$(perfer_proxy download_file_force "$RELEASE_URL")
	TMPD=$(create_temp_dir LiteLoaderQQNT.decompress)
	decompression_file "$DOWNLOADED" 0 "${TMPD}"

	mkdir -p "${TMPD}/plugins"
	for PLUGIN in "${PLUGINS_URL[@]}"; do
		DOWNLOADED=$(perfer_proxy download_file_force "$PLUGIN")
		decompression_file "$DOWNLOADED" 0 "${TMPD}/plugins/$(basename "${PLUGIN%.zip}" .tar.gz)"
	done

	buildah copy "$1" "${TMPD}" "/opt/app"
}
buildah_cache "qqbot" check_LiteLoaderQQNT download_LiteLoaderQQNT
### 安装LiteLoaderQQNT END

merge_local_fs "qqbot" scripts/prepare.sh

setup_systemd "qqbot" \
	networkd ONLINE=no \
	nginx_attach \
	enable "REQUIRE=qqnt.service"

buildah_config "qqbot" \
	--env=LITELOADERQQNT_PROFILE=/opt/loader_data \
	--volume=/opt/loader_data \
	--volume=/home/qq/.cache

buildah_finalize_image "qqbot" gongt/qqbot
