#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE_DNF dnf "force dnf install"
arg_finish

### Runtime Base
source ../systemd-base-image/include.sh
image_base
### Runtime Base END

### 依赖项目
dnf_use_environment
dnf_install_step "network" scripts/dependencies.lst
### 依赖项目 END

STEP="复制配置文件"
merge_local_fs "samba" "scripts/prepare.sh"

setup_systemd "samba" \
	networkd \
	enable REQUIRE="smb.service" WANT="nmb.service"

buildah_config "samba" \
	--volume=/mountpoints --volume=/drives --volume=/opt/config \
	--author="GongT <admin@gongt.me>" --created-by="#MAGIC!" --label=name=gongt/samba

buildah_finalize_image "samba" gongt/samba
info "Done!"
