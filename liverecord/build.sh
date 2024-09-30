#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_finish "$@"

buildah_cache_start "ghcr.io/gongt/systemd-base-image"
dnf_use_environment \
	"--repo=https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" \
	"--repo=https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm" \
	"--enable=fedora-cisco-openh264"
dnf_install_step "liverecord" scripts/dependencies.lst

### 安装
STEP="安装DDTV"
REPO="CHKZL/DDTV"
RELEASE_URL=
hash_download() {
	http_get_github_release_id "$REPO"
	RELEASE_URL=$(github_release_asset_download_url_regex linux-x64)

	cat scripts/after-copy.sh
}
do_download() {
	local TGT=$1 DOWNLOADED TMPD
	TMPD=$(create_temp_dir ddtv.download)
	DOWNLOADED=$(download_file "$RELEASE_URL")
	decompression_file "$DOWNLOADED" 0 "$TMPD"
	buildah copy "$1" "$TMPD" "/opt/app"

	TMPF=$(create_temp_file ddtv.install.sh)
	construct_child_shell_script "${TMPF}" "scripts/after-copy.sh"
	buildah_run_shell_script "$1" "${TMPF}"
}
buildah_cache "liverecord" hash_download do_download
### 安装 END

merge_local_fs liverecord

setup_systemd liverecord \
	socket_proxy PORTS=11419 \
	nginx_attach CONFIG_FILE=/opt/liverecord.nginx.gateway.conf \
	enable "REQUIRE=ddtv.service"

buildah_finalize_image "liverecord" gongt/liverecord
