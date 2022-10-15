#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE f/force "force rebuild qbittorrent source code"
arg_flag FORCE_DNF dnf "force dnf install"
arg_flag FORCE_RSHELL fr "force rebuild remote shell"
arg_finish "$@"

info "starting..."

### 编译时依赖项目
STEP="编译时依赖项目"
hash_compile_deps() {
	dnf_list_version scripts/compile.lst
}
install_compile_deps() {
	info "dnf install..."
	local TARGET="$1" RESULT
	RESULT=$(new_container "$TARGET" fedora)
	run_dnf_with_list_file "$RESULT" scripts/compile.lst
	info "dnf install complete..."
}
BUILDAH_FORCE="$FORCE_DNF" buildah_cache "qbittorrent-build" hash_compile_deps install_compile_deps
### 编译时依赖项目 END

### 编译libtorrent
STEP="编译libtorrent"
download_and_build_github qbittorrent-build libtorrent arvidn/libtorrent RC_1_2
### 编译libtorrent END

### 编译qbittorrent!
STEP="编译qbittorrent"
download_and_build_github qbittorrent-build qbittorrent qbittorrent/qBittorrent
### 编译qbittorrent! END

### 编译remote-shell
STEP="编译remote-shell"
BUILDAH_FORCE="$FORCE_RSHELL" perfer_proxy download_and_build_github qbittorrent-build broadcaster GongT/remote-shell master
### 编译remote-shell END

COMPILE_RESULT_IMAGE="$BUILDAH_LAST_IMAGE"

### 运行时依赖项目
STEP="运行时依赖项目"
cleanup_unused_files() {
	local RESULT=$1
	delete_rpm_files "$RESULT"
	buildah run "$RESULT" bash -c "rm -rf /etc/nginx /etc/privoxy"
}
POST_SCRIPT=cleanup_unused_files make_base_image_by_dnf "qbittorrent" scripts/runtime.lst
### 运行时依赖项目 END

### 编译好的qbt
STEP="复制编译结果文件"
hash_program_files() {
	echo "$COMPILE_RESULT_IMAGE"
}
copy_program_files() {
	info "program copy to target..."
	buildah copy --from "$COMPILE_RESULT_IMAGE" "$1" "/opt/dist" /usr
}
buildah_cache2 "qbittorrent" hash_program_files copy_program_files
### 编译好的qbt END

### 配置文件等
STEP="复制配置文件"
hash_supporting_files() {
	tar -c -f- scripts/prepare-run.sh fs | md5sum
}
copy_supporting_files() {
	info "supporting files copy to target..."
	local RESULT
	RESULT=$(new_container "$1" "$BUILDAH_LAST_IMAGE")
	buildah copy "$RESULT" fs /
	buildah run "$RESULT" bash <"scripts/prepare-run.sh"
}
buildah_cache "qbittorrent" hash_supporting_files copy_supporting_files
### 配置文件等 END

RESULT=$(create_if_not "qbittorrent-final" "$BUILDAH_LAST_IMAGE")
buildah config --cmd "$FEDORA_SYSTEMD_COMMAND" --author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/qbittorrent "$RESULT"
info "settings update..."

buildah commit "$RESULT" gongt/qbittorrent
info "Done!"
