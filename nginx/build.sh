#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE_DNF dnf "force reinstall dependencies"
arg_flag FORCE f/force "force rebuild nginx source code"
arg_finish "$@"

declare -a NGX_SRC_PATH=() NGX_SRC_REPO=() NGX_SRC_BRANCH=()
source ./scripts/nginx-source-registry.sh

if [[ ${#NGX_SRC_PATH[@]} != "${#NGX_SRC_REPO[@]}" ]] || [[ ${#NGX_SRC_BRANCH[@]} != "${#NGX_SRC_REPO[@]}" ]]; then
	die "nginx source settings error"
fi

### 编译时依赖项目
STEP="安装编译时依赖项目"
buildah_cache_start "quay.io/fedora/fedora"
dnf_use_environment
dnf_install_step "nginx-build" scripts/build-requirements.lst
### 编译时依赖项目 END

### 编译!
STEP="下载Nginx源码"
hash_nginx() {
	# 下载代码
	control_ci group "download and hash source code"
	local INDEX REPO BRANCH
	for INDEX in "${!NGX_SRC_REPO[@]}"; do
		REPO="${NGX_SRC_REPO[$INDEX]}"
		BRANCH="${NGX_SRC_BRANCH[$INDEX]}"
		download_github "$REPO" "$BRANCH" >&2
		hash_git_result "$REPO" "$BRANCH"
	done
	control_ci groupEnd
}
build_nginx() {
	local BUILDER="$1" SOURCE_DIRECTORY

	SOURCE_DIRECTORY=$(create_temp_dir "build-source-nginx")
	local INDEX BRANCH NAME
	for INDEX in "${!NGX_SRC_REPO[@]}"; do
		REPO="${NGX_SRC_REPO[$INDEX]}"
		BRANCH="${NGX_SRC_BRANCH[$INDEX]}"
		CPATH="${NGX_SRC_PATH[$INDEX]}"
		NAME="${CPATH////_}"

		download_git_result_copy "$SOURCE_DIRECTORY/$CPATH" "$REPO" "$BRANCH"
	done

	buildah copy --quiet "$BUILDER" "$SOURCE_DIRECTORY" "/opt/projects/nginx"
}
BUILDAH_FORCE="$FORCE" buildah_cache "nginx-build" hash_nginx build_nginx

STEP="编译Nginx源码"
hash_build() {
	cat "scripts/build-nginx.sh"
}
run_build() {
	local SOURCE_DIRECTORY=no
	info_log "(re-)building nginx and modules"
	run_compile nginx "$1" "scripts/build-nginx.sh"
}
buildah_cache "nginx-build" hash_build run_build
### 编译! END

BUILT_RESULT=$(get_last_image_id)

### Runtime Base
source ../systemd-base-image/include.sh
image_base
### Runtime Base END

### 编译好的nginx
dnf_use_environment
dnf_install_step "nginx" scripts/runtime-requirements.lst

STEP="复制Nginx到镜像中"
hash_program_files() {
	echo "source-image: ${BUILT_RESULT}"
	cat "scripts/prepare-run.sh"
}
copy_program_files() {
	run_install "$BUILT_RESULT" "$1" "nginx" "scripts/prepare-run.sh"
}
buildah_cache "nginx" hash_program_files copy_program_files
### 编译好的nginx END

### 配置文件等
STEP="复制配置文件"
merge_local_fs "nginx"
### 配置文件等 END

setup_systemd nginx \
	enable "WANT=reload-cgi.service force-reload-once.timer" "REQUIRE=nginx.service"

healthcheck /usr/sbin/healthcheck.sh
healthcheck_interval 60s
healthcheck_retry 2
healthcheck_startup 30s
healthcheck_timeout 5s

STEP="配置容器"
buildah_config "nginx" --port 80 --port 443 --port 443/udp \
	--volume /config --volume /run/contributed --volume /etc/ACME \
	"--label=${LABELID_USE_NGINX_ATTACH}=yes"

buildah_finalize_image nginx gongt/nginx
info_log "Done."
