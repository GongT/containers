#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE_DNF dnf "force dnf install"
arg_finish

### 依赖项目
make_base_image_by_pacman "infra-build" scripts/dependencies.lst
### 依赖项目 END

setup_systemd "samba"

STEP="复制配置文件"
merge_local_fs "samba" "scripts/prepare.sh"

buildah_config "samba" \
	--volume=/mountpoints --volume=/drives --volume=/opt/config \
	--author="GongT <admin@gongt.me>" --created-by="#MAGIC!" --label=name=gongt/samba

RESULT=$(create_if_not "samba" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/samba
info "Done!"
