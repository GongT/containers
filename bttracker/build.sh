#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE_DNF dnf "force reinstall dependencies"
arg_flag FORCE f/force "force rebuild nginx source code"
arg_finish "$@"

BUILDAH_LAST_IMAGE="fedora"

STEP="安装编译依赖"
dnf_use_environment
dnf_install_step "bttracker-build" scripts/build-deps.lst

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

	control_ci group " * cvs download libowfat..."
	pushd "$SOURCE_DIRECTORY" &>/dev/null
	cvs -d :pserver:cvs@cvs.fefe.de:/cvs -z9 co "libowfat"
	popd &>/dev/null
	control_ci groupEnd

	buildah copy "$BUILDER" "$SOURCE_DIRECTORY" "/opt/projects"
}
BUILDAH_FORCE="$FORCE" buildah_cache "bttracker-build" hash_src download_src

STEP="编译"
hash_build() {
	cat "scripts/compile-opentracker.sh"
}
run_build() {
	local SOURCE_DIRECTORY=no
	info_log "compile opentracker!"
	run_compile opentracker "$1" "scripts/compile-opentracker.sh"
}
buildah_cache "bttracker-build" hash_build run_build
COMPILE_RESULT_IMAGE="$BUILDAH_LAST_IMAGE"

STEP="复制编译结果"
BUILDAH_LAST_IMAGE="fedora"
hash_program_files() {
	echo "$COMPILE_RESULT_IMAGE"
}
copy_program_files() {
	buildah copy "--from=$COMPILE_RESULT_IMAGE" "$1" "/opt/dist" "/usr"
}
buildah_cache "bttracker" hash_program_files copy_program_files

STEP="复制配置文件"
merge_local_fs "bttracker"

STEP="配置容器"
buildah_config "bttracker" --entrypoint "$(json_array /usr/bin/bash)" --shell '/usr/bin/bash' --cmd '/opt/scripts/run.sh' --stop-signal SIGINT --env "DEBUG=yes"
info "settings updated..."

buildah_finalize_image "bttracker" gongt/bttracker
info "Done!"
