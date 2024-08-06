#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

unset PROXY

arg_flag FORCE_DNF dnf "force reinstall dependencies"
arg_flag FORCE f/force "force rebuild nginx source code"
arg_finish "$@"

BUILDAH_LAST_IMAGE="fedora"

STEP="安装编译依赖"
dnf_install "bttracker-build" scripts/build-deps.lst

if is_ci; then
	sudo apt install cvs
fi

STEP="下载源码"
hash_src() {
	download_git "git://erdgeist.org/opentracker" "opentracker" "master"
}
download_src() {
	local BUILDER="$1" SOURCE_DIRECTORY

	SOURCE_DIRECTORY=$(create_temp_dir "opentracker")
	download_git_result_copy "$SOURCE_DIRECTORY/opentracker" "opentracker" "master"

	pushd "$SOURCE_DIRECTORY" &>/dev/null
	cvs -d :pserver:cvs@cvs.fefe.de:/cvs -z9 co "libowfat"
	popd &>/dev/null

	buildah copy "$BUILDER" "$SOURCE_DIRECTORY" "/opt/projects"
}
BUILDAH_FORCE="$FORCE" buildah_cache2 "bttracker-build" hash_src download_src

STEP="编译"
hash_build() {
	cat "scripts/compile-opentracker.sh"
}
run_build() {
	local SOURCE_DIRECTORY=no
	info_log "compile opentracker!"
	run_compile opentracker "$1" "scripts/compile-opentracker.sh"
}
buildah_cache2 "bttracker-build" hash_build run_build
COMPILE_RESULT_IMAGE="$BUILDAH_LAST_IMAGE"

STEP="复制编译结果"
BUILDAH_LAST_IMAGE="fedora"
hash_program_files() {
	echo "$COMPILE_RESULT_IMAGE"
}
copy_program_files() {
	buildah copy "--from=$COMPILE_RESULT_IMAGE" "$1" "/opt/dist" "/usr"
}
buildah_cache2 "bttracker" hash_program_files copy_program_files

STEP="复制配置文件"
merge_local_fs "bttracker"

STEP="配置容器"
buildah_config "bttracker" --entrypoint '/usr/bin/bash' --cmd '/opt/scripts/start.sh' --stop-signal SIGINT
info "settings updated..."

RESULT=$(create_if_not "bttracker" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/bttracker
info "Done!"
