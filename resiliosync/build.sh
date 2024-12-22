#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE f/force "force rebuild"
arg_finish "$@"

### Runtime Base
source ../systemd-base-image/include.sh
image_base
### Runtime Base END

### 运行时依赖项目
STEP="运行时依赖项目"
dnf_use_environment
dnf_install_step "resiliosync" scripts/runtime.lst scripts/post-install.sh
### 运行时依赖项目 END

### 下载hjson
STEP="下载hjson"
REPO="hjson/hjson-go"
get_download() {
	http_get_github_release_id "$REPO"
}
do_download() {
	local URL DOWNLOADED CONTAIENR="$1" TMPD
	URL=$(github_release_asset_download_url_regex linux_amd64)
	DOWNLOADED=$(perfer_proxy download_file_force "$URL")
	TMPD=$(create_temp_dir unzip)
	tar xf "$DOWNLOADED" -C "$TMPD"
	xbuildah copy --chmod 0777 "$CONTAIENR" "$TMPD/hjson" "/usr/bin/hjson"
}
buildah_cache "resiliosync" get_download do_download
### 下载hjson END

### 下载
STEP="下载resilio-sync"
DOWNLOAD_URL=https://download-cdn.resilio.com/stable/linux/x64/0/resilio-sync_x64.tar.gz
get_download() {
	echo "${DOWNLOAD_URL}"
	perfer_proxy http_get_etag "$DOWNLOAD_URL"
}
do_download() {
	local URL DOWNLOADED CONTAIENR="$1" TMPD
	DOWNLOADED=$(perfer_proxy download_file "${DOWNLOAD_URL}")
	TMPD=$(create_temp_dir unzip)
	decompression_file "${DOWNLOADED}" 0 "${TMPD}"
	buildah copy "$CONTAIENR" "$TMPD/rslsync" "/usr/bin/rslsync"
}
buildah_cache "resiliosync" get_download do_download
### 下载 END

### 配置文件等
STEP="复制配置文件"
merge_local_fs "resiliosync"
### 配置文件等 END

setup_systemd "resiliosync" \
	nginx_attach CONFIG_FILE=/opt/nginx-attach.conf \
	enable "REQUIRE=nginx.service rslsync.service"

buildah_finalize_image "resiliosync" gongt/resiliosync
info "Done!"
