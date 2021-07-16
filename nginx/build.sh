#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

unset PROXY

arg_flag FORCE_DNF dnf "force reinstall dependencies"
arg_flag FORCE f/force "force rebuild nginx source code"
arg_finish "$@"

declare -a NGX_SRC_PATH=() NGX_SRC_URL=() NGX_SRC_BRANCH=()
source ./scripts/nginx-source-registry.sh

if [[ ${#NGX_SRC_PATH[@]} != "${#NGX_SRC_URL[@]}" ]] || [[ ${#NGX_SRC_BRANCH[@]} != "${#NGX_SRC_URL[@]}" ]]; then
	die "nginx source settings error"
fi

### 编译时依赖项目
STEP="安装编译时依赖项目"
make_base_image_by_dnf "nginx-build" scripts/build-requirements.lst
### 编译时依赖项目 END

### 编译!
STEP="下载Nginx源码"
hash_nginx() {
	# 下载代码
	local INDEX URL BRANCH NAME
	for INDEX in "${!NGX_SRC_URL[@]}"; do
		URL="${NGX_SRC_URL[$INDEX]}"
		BRANCH="${NGX_SRC_BRANCH[$INDEX]}"
		NAME="${NGX_SRC_PATH[$INDEX]}"
		NAME="${NAME////_}"
		download_git "$URL" "$NAME" "$BRANCH"
	done
}
build_nginx() {
	local BUILDER="$1" SOURCE_DIRECTORY

	SOURCE_DIRECTORY=$(create_temp_dir "build-source-nginx")
	local INDEX BRANCH NAME
	for INDEX in "${!NGX_SRC_URL[@]}"; do
		BRANCH="${NGX_SRC_BRANCH[$INDEX]}"
		CPATH="${NGX_SRC_PATH[$INDEX]}"
		NAME="${CPATH////_}"
		download_git_result_copy "$SOURCE_DIRECTORY/$CPATH" "$NAME" "$BRANCH"
	done

	buildah copy "$BUILDER" "$SOURCE_DIRECTORY" "/opt/projects/nginx"
}
BUILDAH_FORCE="$FORCE" buildah_cache2 "nginx-build" hash_nginx build_nginx

STEP="编译Nginx源码"
hash_build() {
	cat "scripts/build-nginx.sh"
}
run_build() {
	local SOURCE_DIRECTORY=no
	info_log "(re-)building nginx and modules"
	run_compile nginx "$1" "scripts/build-nginx.sh"
}
buildah_cache2 "nginx-build" hash_build run_build
COMPILE_RESULT_IMAGE="$BUILDAH_LAST_IMAGE"
### 编译! END

### 编译好的nginx
buildah_cache_start "gongt/glibc:bash"
STEP="复制Nginx到glibc镜像中"
hash_program_files() {
	echo "$COMPILE_RESULT_IMAGE"
	cat "scripts/prepare-run.sh"
}
copy_program_files() {
	run_install "$COMPILE_RESULT_IMAGE" "$1" "nginx" "scripts/prepare-run.sh"
}
buildah_cache2 "nginx" hash_program_files copy_program_files
### 编译好的nginx END

### 配置文件等
STEP="复制配置文件"
merge_local_fs "nginx"
### 配置文件等 END

info_log ""

buildah_config "nginx" --cmd '/usr/sbin/nginx.sh' --port 80 --port 443 --port 80/udp --port 443/udp \
	--volume /config --volume /etc/ACME \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/nginx

healthcheck "30s" "5" "curl --insecure https://127.0.0.1:443"

RESULT=$(create_if_not nginx "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/nginx
