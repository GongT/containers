#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE_DNF dnf "force dnf install"
arg_finish "$@"

### .Net
STEP="安装.Net"
make_base_image_by_dnf "impostor" scripts/dependencies.lst
### .Net

STEP="下载Impostor"
REPO="Impostor/Impostor"
get_download() {
	http_get_github_release_id "$REPO"
}
do_download() {
	local URL DOWNLOADED TMPD
	TMPD=$(create_temp_dir impostor)
	URL=$(github_release_asset_download_url_regex '^.*linux-x64.*$')
	DOWNLOADED=$(perfer_proxy download_file_force "$URL")
	decompression_file "$DOWNLOADED" 0 "$TMPD"
	buildah copy "$1" "$TMPD/impostor" "/app"
}
buildah_cache2 "impostor" get_download do_download

STEP="复制配置文件"
merge_local_fs "impostor"

STEP="配置镜像"
buildah_config "impostor" \
	--cmd "/opt/init.sh" \
	--author "GongT <admin@gongt.me>" \
	--created-by "#MAGIC!" \
	--label name=gongt/impostor

RESULT=$(create_if_not impostor-result "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/impostor
info "Done!"
