#!/usr/bin/env bash

set -Eeuo pipefail

declare -r FEDORA_VERSION=42

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

### 依赖项目
STEP="安装系统依赖"
dnf_use_environment --repo=https://rpms.remirepo.net/fedora/remi-release-40.rpm
dnf_install_step "wordpress" scripts/deps.lst
### 依赖项目 END

merge_local_fs wordpress

buildah_finalize_image wordpress gongt/wordpress
info "Done!"
