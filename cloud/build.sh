#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

### 依赖项目
STEP="安装系统依赖"
declare -a DEPS
mapfile -t DEPS < <(cat scripts/deps.lst)
make_base_image_by_apk registry.gongt.me/gongt/init "nextcloud" "${DEPS[@]}"
### 依赖项目 END

RESULT=$(create_if_not cloud-worker "$BUILDAH_LAST_IMAGE")

buildah run "$RESULT" sh < scripts/build-script.sh
info "install complete..."

buildah copy "$RESULT" fs /
info "copy config files complete..."

buildah config --author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/cloud "$RESULT"
info "settings updated..."

buildah commit "$RESULT" gongt/cloud
info "Done!"
