#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

### 依赖项目
STEP="安装编译依赖"
make_base_image_by_dnf "btc-build" scripts/dependencies.lst
### 依赖项目 END

### 下载&编译
STEP="bitcoin 代码"
download_and_build_github_release "btc-build" bitcoind "bitcoin/bitcoin"
BUILT_IMAGE="$BUILDAH_LAST_IMAGE"
### 下载&编译 END

### 复制文件
buildah_cache_start "gongt/glibc:bash"

STEP="复制编译结果和依赖文件到目标容器"
hash_program_files() {
	cat "scripts/prepare-deps.sh"
}
copy_program_files() {
	local RESULT="$1"

	run_install "$BUILT_IMAGE" "$RESULT" bitcoind "scripts/prepare-deps.sh"

	buildah unshare bash <<-EOF
		RESULT_MNT=\$(buildah mount "$RESULT")
		rm -rf "\$RESULT_MNT/data"
		mkdir "\$RESULT_MNT/data"
		chattr +i "\$RESULT_MNT/data"
		buildah unmount "$RESULT"
	EOF

	VERSION=$(xbuildah run "$RESULT" bitcoind --version | grep 'Bitcoin Core version ' | sed 's#Bitcoin Core version ##g')
	info "VERSION = $VERSION"

	buildah config --label "bitcoind-version=$VERSION" "$RESULT"
}
buildah_cache2 "btc" hash_program_files copy_program_files
### 复制文件 END

### 复制fs
STEP="复制配置文件"
merge_local_fs "btc"
### 复制fs END

buildah_config "btc" --cmd '/opt/start.sh' --port 8332 --port 8333 --port 8332/udp --port 8333/udp \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/bitcoin-peer

RESULT=$(new_container "btc" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/bitcoin-peer
info "Done!"
