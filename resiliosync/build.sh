#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE f/force "force rebuild"
arg_finish "$@"

info "starting..."

### 运行时依赖项目
STEP="运行时依赖项目"
cleanup_unused_files() {
	local RESULT=$1
	delete_rpm_files "$RESULT"
	buildah run "$RESULT" bash -c "rm -rf /etc/nginx"
}
dnf_add_repo_string resilio '[resilio-sync]
name=Resilio Sync
baseurl=https://linux-packages.resilio.com/resilio-sync/rpm/$basearch
enabled=1
gpgcheck=0'
POST_SCRIPT=cleanup_unused_files make_base_image_by_dnf "resiliosync" scripts/runtime.lst
### 运行时依赖项目 END

### sbin/init
download_and_install_x64_init "resiliosync"
### sbin/init END

### hjson
REPO="hjson/hjson-go"
get_download() {
	http_get_github_release_id "$REPO"
}
do_download() {
	local URL DOWNLOADED CONTAIENR="$1"
	URL=$(github_release_asset_download_url_regex linux)
	DOWNLOADED=$(perfer_proxy download_file_force "$URL")
	xbuildah copy --chmod 0777 "$CONTAIENR" "$DOWNLOADED" "/usr/bin/hjson"
}
buildah_cache2 "resiliosync" get_download do_download
### hjson END

### 配置文件等
STEP="复制配置文件"
merge_local_fs "resiliosync"
### 配置文件等 END

buildah_config "resiliosync" --cmd '/opt/init.sh' --stop-signal SIGINT \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/resiliosync

RESULT=$(create_if_not "resiliosync" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/resiliosync
info "Done!"
