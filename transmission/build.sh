#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE f/force "force re-download binary"
arg_finish "$@"

info "starting..."

### 依赖项目
STEP="运行时依赖项目"
fork_archlinux "transmission" scripts/dependencies.lst
### 依赖项目 END

setup_systemd "transmission" nginx_attach

STEP="复制文件"
merge_local_fs "transmission" scripts/prepare-run.sh

buildah_config "transmission" \
	--volume /opt/data \
	--volume /opt/config \
	--author "GongT <admin@gongt.me>" \
	--created-by "#MAGIC!" \
	--label name=gongt/transmission

buildah_finalize_image "transmission" gongt/transmission
info "Done!"
