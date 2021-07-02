#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE_DNF dnf "force dnf install"
arg_finish

### 依赖项目
STEP="安装系统依赖"
make_base_image_by_dnf "samba" scripts/dependencies.lst
### 依赖项目 END

STEP="复制配置文件"
merge_local_fs "samba" "scripts/prepare.sh"

buildah_config "samba" --cmd "$FEDORA_SYSTEMD_COMMAND" \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/samba

RESULT=$(create_if_not "samba" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/samba
info "Done!"
