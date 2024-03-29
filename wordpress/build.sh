#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."
RESULT=$(create_if_not wordpress-worker registry.gongt.me/gongt/init)

### 依赖项目
STEP="安装系统依赖"
declare -a DEPS
mapfile -t DEPS < <(cat scripts/deps.lst)
make_base_image_by_apk registry.gongt.me/gongt/init "wordpress-build" "${DEPS[@]}"
### 依赖项目 END

RESULT=$(create_if_not wordpress-worker "$BUILDAH_LAST_IMAGE")

buildah copy "$RESULT" fs /
buildah config --author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/wordpress "$RESULT"
info "settings updated..."

buildah commit "$RESULT" gongt/wordpress
info "Done!"
