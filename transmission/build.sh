#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE f/force "force re-download binary"
arg_finish "$@"

info "starting..."


### Runtime Base
record_last_base_name "ghcr.io/gongt/systemd-base-image:latest"
source ../systemd-base-image/include.sh
image_base # graphical
### Runtime Base END

### 依赖项目
STEP="运行时依赖项目"
dnf_use_environment
dnf_install_step "transmission" scripts/dependencies.lst
### 依赖项目 END

STEP="复制配置文件并准备运行环境"
merge_local_fs "transmission" scripts/prepare-run.sh

setup_systemd "transmission" \
	nginx_attach "CONFIG_FILE=/opt/nginx.attach.conf" \
	networkd \
	enable "REQUIRE=transmission.service" "BACKGROUND=chown-data.service"

buildah_config "transmission" \
	--volume /opt/data \
	--volume /opt/config \
	--author "GongT <admin@gongt.me>" \
	--created-by "#MAGIC!" \
	--label name=gongt/transmission

buildah_finalize_image "transmission" gongt/transmission
info "Done!"
