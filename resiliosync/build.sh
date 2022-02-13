#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE f/force "force rebuild"
arg_finish "$@"

info "starting..."

### 运行时依赖项目
STEP="运行时依赖项目"
cleanup_unused_files() {
	local RESULT=$1
	delete_rpm_files "$RESULT"
	buildah run "$RESULT" bash -c "rm -rf /etc/nginx"
}
POST_SCRIPT=cleanup_unused_files make_base_image_by_dnf "resiliosync" scripts/runtime.lst
### 运行时依赖项目 END

### sbin/init
download_and_install_x64_init "resiliosync"
### sbin/init END

### 配置文件等
STEP="复制配置文件"
merge_local_fs "resiliosync"
### 配置文件等 END

buildah_config "resiliosync" --cmd '/usr/sbin/init' --stop-signal SIGINT \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/resiliosync

RESULT=$(create_if_not "resiliosync" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/resiliosync
info "Done!"
