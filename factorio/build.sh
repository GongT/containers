#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

declare -xr DIST_URL="https://www.factorio.com/get-download/stable/headless/linux64"

arg_finish "$@"

### 编译时依赖项目
STEP="安装系统依赖"
declare -ra COMPILE_DEPS=(glibc sed)
make_base_image_by_dnf "factorio-install" "${COMPILE_DEPS[@]}"
### 编译时依赖项目 END

### 下载安装
STEP="下载factorio可执行文件"
hash_factorio() {
	run_without_proxy http_get_etag "$DIST_URL"
}
build_factorio() {
	local CNTR MNT DOWNLOADED VERSION
	CNTR=$(new_container "$1" "$BUILDAH_LAST_IMAGE")
	MNT=$(buildah mount "$CNTR")
	DOWNLOADED=$(download_file "$DIST_URL" "$WANTED_HASH")
	extract_tar "$DOWNLOADED" 1 "$MNT/opt/factorio"
	VERSION=$("$MNT/opt/factorio/bin/x64/factorio" --version | head -n 1)
	buildah config --label "VERSION=$VERSION" "$CNTR"
	info "Factorio $VERSION"
}
buildah_cache "factorio-build" hash_factorio build_factorio
### 下载安装 END

RESULT=$(new_container "factorio-final" "$BUILDAH_LAST_IMAGE")
buildah copy "$RESULT" fs /
info "result files copy complete..."

buildah config --cmd '/opt/scripts/start.sh' --port 34197 --stop-signal SIGINT "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/factorio "$RESULT"
info "settings update..."

buildah commit "$RESULT" gongt/factorio
info "Done!"
