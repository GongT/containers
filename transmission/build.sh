#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE_DNF dnf "force dnf install"
arg_finish "$@"

info "starting..."

STEP="运行时依赖项目"
make_base_image_by_dnf "transmission" scripts/runtime.lst

STEP="复制文件"
merge_local_fs "transmission" scripts/prepare-run.sh

buildah_config "transmission" \
	--volume /opt/data \
	--cmd "bash /opt/scripts/start.sh" \
	--author "GongT <admin@gongt.me>" \
	--created-by "#MAGIC!" \
	--label name=gongt/qbittorrent

buildah commit "$RESULT" gongt/qbittorrent
info "Done!"
