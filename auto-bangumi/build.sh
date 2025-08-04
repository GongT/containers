#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

buildah_cache_start "ghcr.io/gongt/qbittorrent"

###
dnf_use_environment
dnf_install_step "auto-bangumi" scripts/build-requirements.lst
###

###
STEP="安装AutoBangumi"
REPO="EstrellaXD/Auto_Bangumi"
get_download() {
	http_get_github_release_id "$REPO"
}
do_download() {
	local URL DOWNLOADED
	URL=$(github_release_asset_download_url_regex 'app-.*\.zip')
	DOWNLOADED=$(perfer_proxy download_file "$URL" "$(__github_release_json_id).zip")
	local TMPD
	TMPD=$(create_temp_dir "auto-bangumi")
	decompression_file "$DOWNLOADED" 1 "$TMPD"
	buildah copy "$1" "$TMPD" "/app"
}
buildah_cache "auto-bangumi" get_download do_download
###

###
noop() {
	:
}
install_python_requirements(){
	buildah run "$1" python3 -m pip install "${PIP_INSTALL_ARGS[@]}" -r "/app/requirements.txt"
}
buildah_cache "auto-bangumi" noop install_python_requirements
###

### 配置文件等
STEP="复制配置文件"
merge_local_fs "auto-bangumi" "scripts/prepare-run.sh"
### 配置文件等 END

setup_systemd "auto-bangumi" \
	basic DEFAULT_TARGET=graphical.target \
	networkd ONLINE=yes \
	nginx_attach CONFIG_FILE=/opt/nginx-attach.conf \
	enable "REQUIRE=auto-bangumi.service"

buildah_finalize_image "auto-bangumi" gongt/auto-bangumi
