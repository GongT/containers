#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE_DNF dnf "force dnf install"
arg_finish "$@"

buildah_cache_start "quay.io/fedora/fedora-minimal"

### TGTD
STEP="安装 iscsi-tgtd"
dnf_use_environment
dnf_install_step "fedora-tgtd" source/dependencies.lst source/post-install.sh
### TGTD END

### 复制文件
STEP="复制文件"
merge_local_fs "fedora-tgtd"
### 安装acme END

setup_systemd "fedora-tgtd" \
	enable REQUIRE="tgtd.service" WANT="iperf3-server@33233.service"

buildah_finalize_image "fedora-tgtd" gongt/gamedisk
info "Done!"
