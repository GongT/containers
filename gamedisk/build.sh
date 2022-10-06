#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE_DNF dnf "force dnf install"
arg_finish "$@"

info "starting..."

### TGTD
STEP="install iscsi-tgtd"
make_base_image_by_dnf "fedora-tgtd" source/dependencies.lst
### TGTD END

### init
download_and_install_x64_init "fedora-tgtd"
### init END

### 复制文件
STEP="复制文件"
merge_local_fs "fedora-tgtd"
### 安装acme END

STEP="配置镜像信息"
buildah_config "fedora-tgtd" --stop-signal SIGINT \
	--volume /var/lib/dhclient \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/gamedisk
info "settings update..."

RESULT=$(create_if_not "gamedisk" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/gamedisk
info "Done!"
