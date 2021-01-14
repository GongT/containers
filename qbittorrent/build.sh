#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE f/force "force rebuild qbittorrent source code"
arg_flag FORCE_DNF dnf "force dnf install"
arg_finish "$@"

info "starting..."

### 编译时依赖项目
hash_compile_deps() {
	tar -c -f- scripts/compile.lst scripts/prepare-golang.sh | md5sum
}
install_compile_deps() {
	info "dnf install..."
	local TARGET="$1" RESULT
	RESULT=$(new_container "$TARGET" fedora)
	run_dnf "$RESULT" $(<scripts/compile.lst)
	info "dnf install complete..."

	{
		SHELL_USE_PROXY
		cat scripts/prepare-golang.sh
	} | buildah run "$RESULT" bash
}
BUILDAH_FORCE="$FORCE_DNF" buildah_cache "qbittorrent-build" hash_compile_deps install_compile_deps
### 编译时依赖项目 END

### 编译libtorrent
hash_libtorrent() {
	fast_hash_path source/libtorrent scripts/build-libtorrent.sh
}
build_libtorrent() {
	clean_submodule source/libtorrent
	run_compile "libtorrent" "$1" "./scripts/build-libtorrent.sh"
	info "libtorrent build complete..."
}
buildah_cache2 "qbittorrent-build" hash_libtorrent build_libtorrent
### 编译! END

### 编译!
hash_qbittorrent() {
	git ls-tree -r HEAD source/qbittorrent scripts/build-qbittorrent.sh
}
build_qbittorrent() {
	clean_submodule source/qbittorrent
	run_compile "qbittorrent" "$1" "./scripts/build-qbittorrent.sh"
	info "qbittorrent build complete..."
}
buildah_cache2 "qbittorrent-build" hash_qbittorrent build_qbittorrent
COMPILE_RESULT_IMAGE="$BUILDAH_LAST_IMAGE"
### 编译! END

### 运行时依赖项目
hash_runtime_deps() {
	md5sum scripts/runtime.lst
}
install_runtime_deps() {
	info "dnf install..."
	local TARGET="$1" RESULT
	RESULT=$(new_container "$TARGET" scratch)
	run_dnf "$RESULT" $(<scripts/runtime.lst)
	info "dnf install complete..."
	delete_rpm_files "$RESULT"
	buildah run "$RESULT" bash -c "rm -rf /etc/nginx /etc/privoxy"
}
BUILDAH_FORCE="$FORCE_DNF" buildah_cache "qbittorrent" hash_runtime_deps install_runtime_deps
### 运行时依赖项目 END

### 编译好的qbt
hash_program_files() {
	echo "$BUILDAH_LAST_IMAGE" | md5sum --binary -
}
copy_program_files() {
	info "program copy to target..."
	local PROGRAM PROGRAM_MNT
	PROGRAM=$(create_if_not qbittorrent-result-copyout "$COMPILE_RESULT_IMAGE")
	PROGRAM_MNT=$(buildah mount "$PROGRAM")
	info "program prepared..."

	local RESULT
	RESULT=$(new_container "$1" "$BUILDAH_LAST_IMAGE")
	buildah copy "$RESULT" "$PROGRAM_MNT/opt/dist" /usr

	buildah unmount "$PROGRAM" >/dev/null
	buildah rm "$PROGRAM" >/dev/null
}
buildah_cache "qbittorrent" hash_program_files copy_program_files
### 编译好的qbt END

### 配置文件等
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
