#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE f/force "force re-download binary"
arg_flag FORCE_DNF dnf "force dnf install"
arg_finish "$@"

info "starting..."

buildah_cache_start "fedora:$FEDORA_VERSION"

STEP="运行时依赖项目"
dnf_install "transmission" scripts/runtime.lst

setup_systemd "transmission" \
	nginx_config=/opt/scripts/nginx.conf nginx_attach

STEP="复制文件"
merge_local_fs "transmission" scripts/prepare-run.sh

buildah_config "transmission" \
	--volume /opt/data \
	--volume /opt/config \
	--author "GongT <admin@gongt.me>" \
	--created-by "#MAGIC!" \
	--label name=gongt/transmission

RESULT=$(new_container "transmission" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/transmission
info "Done!"
