#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

buildah_cache_start "archlinux:latest"

### 依赖项目
make_base_image_by_pacman "infra-build" curl iperf3 systemd jq ipcalc
### 依赖项目 END

### 配置文件等
STEP="复制配置文件"
merge_local_fs "infra-build"
### 配置文件等 END

setup_systemd "infra-build"

buildah_cache_run "infra-build" scripts/prepare-env.sh

buildah_config "infra-build" --author "GongT <admin@gongt.me>" --label name=gongt/virtual-gateway
info "settings update..."

RESULT=$(create_if_not "infra-result" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/virtual-gateway
info "Done!"
