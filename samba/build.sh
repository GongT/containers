#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE_DNF dnf "force dnf install"
arg_finish

### 依赖项目
STEP="安装系统依赖"
make_base_image_by_dnf "samba-install" scripts/dependencies.lst
### 依赖项目 END

RESULT=$(new_container "samba-final" "$BUILDAH_LAST_IMAGE")
buildah copy "$RESULT" fs /
cat "scripts/prepare.sh" | buildah run "$RESULT" bash

buildah config --cmd "$FEDORA_SYSTEMD_COMMAND" "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/samba "$RESULT"
info "settings update..."

buildah commit "$RESULT" gongt/samba
info "Done!"
