#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_finish "$@"

buildah_cache_start "ghcr.io/gongt/systemd-base-image"

### 依赖项目
# STEP="安装系统依赖"
# dnf_use_environment
# dnf_install_step "factorio" source/dependencies.lst
### 依赖项目 END

### 下载安装
STEP="下载factorio可执行文件"
hash_factorio() {
	local -r DIST_URL="https://factorio.com/get-download/$DIST_TAG/headless/linux64"
	local ETAG
	ETAG=$(perfer_proxy http_get_etag "$DIST_URL")
	echo -n "$DIST_TAG::$ETAG"
}
build_factorio() {
	local -r CNTR="$1"
	local -r DIST_URL="https://factorio.com/get-download/$DIST_TAG/headless/linux64"
	local -r GAME_ROOT="/opt/factorio/$DIST_TAG"
	local DOWNLOADED VERSION EXTRACTED

	DOWNLOADED=$(perfer_proxy download_file_force "$DIST_URL")
	EXTRACTED=$(create_temp_dir factorio_binary)
	extract_tar "$DOWNLOADED" 1 "$EXTRACTED"

	buildah copy "$CNTR" "$EXTRACTED" "$GAME_ROOT"

	VERSION=$(buildah run "$CNTR" "$GAME_ROOT/bin/x64/factorio" --version | head -n 1)
	buildah config \
		--label "factorio.version=${DIST_TAG}:$VERSION" \
		"$CNTR"
	info "Factorio $VERSION"
}

DIST_TAG="stable" buildah_cache "factorio" hash_factorio build_factorio
# DIST_TAG="latest" buildah_cache "factorio" hash_factorio build_factorio
### 下载安装 END

merge_local_fs "factorio"

setup_systemd "factorio" \
	enable REQUIRE=factorio-stable.service

buildah_config factorio --port 34197
info "settings update..."

buildah_finalize_image "factorio" gongt/factorio

info "Done!"
