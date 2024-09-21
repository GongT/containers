#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE f/force "force rebuild qbittorrent source code"
arg_flag FORCE_DNF dnf "force dnf install"
arg_flag FORCE_RSHELL fr "force rebuild remote shell"
arg_finish "$@"

info "starting..."



### 编译时依赖项目
STEP="编译时依赖项目"
buildah_cache_start "quay.io/fedora/fedora"
dnf_use_environment
dnf_install_step "qbittorrent-build" scripts/compile.lst
### 编译时依赖项目 END

# ### 编译libtorrent
# STEP="编译libtorrent"
# download_and_build_github qbittorrent-build libtorrent arvidn/libtorrent RC_1_2
# ### 编译libtorrent END

# ### 编译qbittorrent!
# STEP="编译qbittorrent"
# download_and_build_github qbittorrent-build qbittorrent qbittorrent/qBittorrent
# ### 编译qbittorrent! END

### 编译remote-shell
STEP="编译remote-shell"
BUILDAH_FORCE="$FORCE_RSHELL" perfer_proxy download_and_build_github qbittorrent-build broadcaster GongT/remote-shell master
### 编译remote-shell END

COMPILE_RESULT_IMAGE=$(get_last_image_id)

### 运行时依赖项目
STEP="运行时依赖项目"
buildah_cache_start "quay.io/fedora/fedora-minimal"
dnf_use_environment
dnf_install_step "qbittorrent" scripts/runtime.lst scripts/post-install-cleanup.sh
### 运行时依赖项目 END

### 编译好的qbt
STEP="复制编译结果文件"
hash_program_files() {
	echo "$COMPILE_RESULT_IMAGE"
}
copy_program_files() {
	info "program copy to target..."
	buildah copy --from "$COMPILE_RESULT_IMAGE" "$1" "/opt/dist" /usr
}
buildah_cache "qbittorrent" hash_program_files copy_program_files
### 编译好的qbt END

### 配置文件等
STEP="复制配置文件"
merge_local_fs "qbittorrent" "scripts/prepare-run.sh"
### 配置文件等 END

setup_systemd "qbittorrent" \
	basic DEFAULT_TARGET=graphical.target \
	enable "WANT=qbittorrent.service" "REQUIRE=i3.service"

# STEP="配置镜像信息"
# buildah_config qbittorrent --author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/qbittorrent
# info "settings update..."

buildah_finalize_image "qbittorrent" gongt/qbittorrent
info "Done!"
