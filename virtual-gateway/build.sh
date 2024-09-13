#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

### 依赖项目
fork_archlinux "infra-build" curl iperf3 systemd jq ipcalc vim
### 依赖项目 END

### 配置文件等
STEP="复制配置文件"
merge_local_fs "infra-build"
### 配置文件等 END

setup_systemd "infra-build" \
	enable UNITS="systemd-networkd.service systemd-resolved.service ddns.timer"

buildah_config "infra-build" --author "GongT <admin@gongt.me>" --label name=gongt/virtual-gateway
info "settings update..."

buildah_finalize_image "infra-result" gongt/virtual-gateway
info "Done!"
