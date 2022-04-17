#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE f/force "force rebuild source code"
arg_flag FORCE_DNF dnf "force dnf install"
arg_finish "$@"

info "starting..."

### 编译时依赖项目
STEP="编译时依赖项目"
BUILDAH_FORCE="$FORCE_DNF" make_base_image_by_dnf "transmission-build" scripts/compile.lst
### 编译时依赖项目 END

### 编译transmission
STEP="编译transmission"
download_and_build_github "transmission-build" transmission transmission/transmission
COMPILE_RESULT_IMAGE="$BUILDAH_LAST_IMAGE"
### 编译transmission END

STEP="运行时依赖项目"
make_base_image_by_dnf "transmission" scripts/runtime.lst

### 编译好的qbt
STEP="复制编译结果文件"
hash_program_files() {
	echo "$COMPILE_RESULT_IMAGE"
}
copy_program_files() {
	info "program copy to target..."
	buildah copy --from "$COMPILE_RESULT_IMAGE" "$1" "/opt/dist" /usr
}
buildah_cache2 "transmission" hash_program_files copy_program_files
### 编译好的qbt END

STEP="复制文件"
merge_local_fs "transmission" scripts/prepare-run.sh

buildah_config "transmission" \
	--volume /opt/data \
	--volume /opt/config \
	--cmd "bash /opt/scripts/start.sh" \
	--author "GongT <admin@gongt.me>" \
	--created-by "#MAGIC!" \
	--label name=gongt/qbittorrent

RESULT=$(new_container "transmission" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/transmission
info "Done!"
