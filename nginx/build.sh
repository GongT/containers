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
mapfile -t COMPILE_DEPS < requirements/build.lst
make_base_image_by_dnf "nginx-build" "${COMPILE_DEPS[@]}"
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
	local RESULT
	RESULT=$(new_container "$1" "gongt/glibc:bash")
	RESULT_MNT=$(buildah mount "$RESULT")

	run_install "nginx" "$COMPILE_RESULT_IMAGE" "$RESULT_MNT" "tools/prepare-run.sh"
	buildah unmount "$RESULT" > /dev/null
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
