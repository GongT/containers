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
buildah_cache_start "registry.fedoraproject.org/fedora"
dnf_use_environment
dnf_install_step "nginx-build" scripts/build-requirements.lst
### 编译时依赖项目 END

### 编译!
STEP="下载Nginx源码"
NGX_COMMIT_ID_LIST=()
hash_nginx() {
	# 下载代码
	control_ci group "download and hash source code"
	local INDEX REPO BRANCH NAME COMMID
	for INDEX in "${!NGX_SRC_REPO[@]}"; do
		REPO="${NGX_SRC_REPO[$INDEX]}"
		BRANCH="${NGX_SRC_BRANCH[$INDEX]}"
		NAME="${NGX_SRC_PATH[$INDEX]}"
		NAME="${NAME////_}"
		COMMID=""
		if [[ ${BRANCH} == '@@'* ]]; then
			BRANCH=${BRANCH#@@}
			COMMID=$(http_get_github_tag_commit "$REPO")
		fi
		NGX_COMMIT_ID_LIST+=("$COMMID")
		download_github "$REPO" "$NAME" "$BRANCH" >&2
		if [[ -n ${COMMID} ]]; then
			echo "${COMMID}"
		else
			hash_git_result "$NAME" "$BRANCH"
		fi
	done
	control_ci groupEnd
}
build_nginx() {
	local BUILDER="$1" SOURCE_DIRECTORY

	SOURCE_DIRECTORY=$(create_temp_dir "build-source-nginx")
	local INDEX BRANCH NAME COMMID
	for INDEX in "${!NGX_SRC_REPO[@]}"; do
		BRANCH="${NGX_SRC_BRANCH[$INDEX]}"
		CPATH="${NGX_SRC_PATH[$INDEX]}"
		COMMID="${NGX_COMMIT_ID_LIST[$INDEX]}"
		NAME="${CPATH////_}"

		if [[ -z ${COMMID} ]]; then
			COMMID="origin/${BRANCH}"
		fi

		download_git_result_copy "$SOURCE_DIRECTORY/$CPATH" "$NAME" "$COMMID"
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

### 编译好的nginx
buildah_cache_start "registry.fedoraproject.org/fedora-minimal"
dnf_use_environment
dnf_install_step "nginx" scripts/runtime-requirements.lst
STEP="复制Nginx到镜像中"
hash_program_files() {
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

healthcheck /usr/sbin/healthcheck.sh
healthcheck_interval 60s
healthcheck_retry 2
healthcheck_startup 30s
healthcheck_timeout 5s

custom_reload_command bash /usr/bin/safe-reload
custom_stop_command bash /usr/sbin/graceful-shutdown.sh

STEP="配置容器"
buildah_config "nginx" --cmd '/usr/sbin/nginx.sh' --port 80 --port 443 --port 80/udp --port 443/udp \
	--volume /config --volume /etc/ACME --stop-signal=SIGQUIT \
	"--label=${LABELID_USE_NGINX_ATTACH}=yes" "--volume=/run/nginx" "--volume=/run/sockets" \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/nginx

buildah_finalize_image nginx gongt/nginx
info_log "Done."
