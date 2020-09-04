#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

unset PROXY

arg_flag FORCE_DNF dnf "force reinstall dependencies"
arg_flag FORCE f/force "force rebuild nginx source code"
arg_finish "$@"

### 编译时依赖项目
STEP="install system dependencies during compile"
hash_compile_deps() {
	md5sum requirements/build.lst
}
install_compile_deps() {
	info "dnf install..."
	local TARGET="$1" RESULT
	RESULT=$(new_container "$TARGET" scratch)
	run_dnf "$RESULT" $(< requirements/build.lst)
	info "dnf install complete..."
}
BUILDAH_FORCE="$FORCE_DNF" buildah_cache "nginx-build" hash_compile_deps install_compile_deps
### 编译时依赖项目 END

### 编译!
STEP="compile nginx source code"
hash_nginx() {
	md5sum tools/build-nginx.sh
}
build_nginx() {
	local BUILDER
	BUILDER=$(new_container "$1" "$BUILDAH_LAST_IMAGE")

	SOURCE_DIRECTORY=source run_compile "nginx" "$BUILDER" "tools/build-nginx.sh"

	info "nginx build complete..."
}
BUILDAH_FORCE="$FORCE" buildah_cache "nginx-build" hash_nginx build_nginx
COMPILE_RESULT_IMAGE="$BUILDAH_LAST_IMAGE"
### 编译! END

### 编译好的nginx
STEP="copy compiled files into base image"
hash_program_files() {
	{
		cat "tools/prepare-run.sh"
	} | md5sum
}
copy_program_files() {
	info "program copy to target..."
	local PROGRAM PROGRAM_MNT
	PROGRAM=$(create_if_not nginx-result-copyout "$COMPILE_RESULT_IMAGE")
	PROGRAM_MNT=$(buildah mount "$PROGRAM")
	info "program prepared..."

	local RESULT
	RESULT=$(new_container "$1" "busybox")

	cat "tools/prepare-run.sh" \
		| buildah run \
			"--volume=$PROGRAM_MNT/opt/dist:/mnt" \
			"$RESULT" sh

	buildah unmount "$PROGRAM" > /dev/null
	buildah rm "$PROGRAM" > /dev/null
}
buildah_cache "nginx" hash_program_files copy_program_files
### 编译好的nginx END

### 配置文件等
STEP="copy config files"
hash_supporting_files() {
	tar -c -f- fs | md5sum
}
copy_supporting_files() {
	info "supporting files copy to target..."
	local RESULT
	RESULT=$(new_container "$1" "$BUILDAH_LAST_IMAGE")
	buildah copy "$RESULT" fs /
}
buildah_cache "nginx" hash_supporting_files copy_supporting_files
### 配置文件等 END

info_log ""

RESULT=$(new_container "nginx-final" "$BUILDAH_LAST_IMAGE")
buildah config --cmd '/usr/sbin/nginx.sh' --env PATH="/bin:/usr/bin:/usr/sbin" \
	--port 80 --port 443 --port 80/udp --port 443/udp "$RESULT"
buildah config --volume /config --volume /etc/letsencrypt "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "GongT" --label name=gongt/nginx "$RESULT"
info "settings update..."
info_log ""

buildah commit "$RESULT" gongt/nginx
info "Done!"
