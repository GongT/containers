#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

### 依赖项目
fork_archlinux "network" curl iperf3 systemd jq ipcalc vim
### 依赖项目 END

### 配置文件等
STEP="复制配置文件"
merge_local_fs "network"
### 配置文件等 END

setup_systemd "network" \
	enable UNITS="systemd-networkd.service systemd-resolved.service ddns.timer"

buildah_config "network" --author "GongT <admin@gongt.me>" --label name=gongt/gateway-network
info "settings update..."

buildah_finalize_image "network" gongt/gateway-network
info "Done!"
