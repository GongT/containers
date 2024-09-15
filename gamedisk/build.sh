#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE_DNF dnf "force dnf install"
arg_finish "$@"

info "starting..."

buildah_cache_start "fedora-minimal"

### TGTD
STEP="install iscsi-tgtd"
dnf_use_environment
dnf_install_step "fedora-tgtd" source/dependencies.lst
### TGTD END

setup_systemd "fedora-tgtd"

### 复制文件
STEP="复制文件"
merge_local_fs "fedora-tgtd" source/post-copy.sh
### 安装acme END

STEP="配置镜像信息"
buildah_config "fedora-tgtd" --stop-signal SIGINT \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/gamedisk
info "settings update..."

buildah_finalize_image "gamedisk" gongt/gamedisk
info "Done!"
