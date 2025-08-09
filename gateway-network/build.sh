#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_finish "$@"

### Runtime Base
source ../systemd-base-image/include.sh
image_base
### Runtime Base END

### 依赖项目
dnf_install_step "network" scripts/requirements.lst
### 依赖项目 END

### 配置文件等
STEP="复制配置文件"
merge_local_fs "network"
### 配置文件等 END

setup_systemd "network" \
	networkd \
	enable REQUIRE="systemd-networkd.service ddns.timer"

buildah_config "network" --author "GongT <admin@gongt.me>" --label name=gongt/gateway-network
info "settings update..."

buildah_finalize_image "network" gongt/gateway-network
info "Done!"
