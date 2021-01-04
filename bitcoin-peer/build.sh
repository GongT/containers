#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

### 依赖项目
STEP="安装编译依赖"
DEPS=(bash python3 clang rpm libtool make autoconf automake libevent-devel boost-devel e2fsprogs)
make_base_image_by_dnf "btc-build" "${DEPS[@]}"
### 依赖项目 END

### 下载&编译
REPO="bitcoin/bitcoin"
RELEASE_URL=""
RELEASE_NAME=""
STEP="下载 bitcoin 代码"
hash_wireguard() {
	http_get_github_release_id "$REPO"
	RELEASE_URL=$(echo "$LAST_GITHUB_RELEASE_JSON" | jq -r '.tarball_url')
	info_note "       * RELEASE_URL=$RELEASE_URL"
	RELEASE_NAME=$(echo "$LAST_GITHUB_RELEASE_JSON" | jq -r '.tag_name')
	info_note "       * RELEASE_NAME=$RELEASE_NAME"
}
compile_wireguard() {
	local RESULT DOWNLOADED VERSION FILE_NAME="bitcoin.$RELEASE_NAME.tar.gz"
	DOWNLOADED=$(download_file "$RELEASE_URL" "$FILE_NAME")
	SOURCE_DIRECTORY="$(pwd)/source/bitcoin"
	rm -rf "$SOURCE_DIRECTORY"
	extract_tar "$DOWNLOADED" "1" "$SOURCE_DIRECTORY"

	RESULT=$(new_container "$1" "$BUILDAH_LAST_IMAGE")
	run_compile "bitcoin" "$RESULT" "source/builder.sh"
}
buildah_cache "btc-build" hash_wireguard compile_wireguard
### 下载&编译 END

### 复制文件
STEP="复制编译结果和依赖文件到目标容器"
hash_program_files() {
	{
		image_get_id "gongt/glibc:bash"
		cat "source/prepare-deps.sh"
	} | md5sum
}
copy_program_files() {
	local RESULT
	RESULT=$(new_container "$1" "gongt/glibc:bash")
	RESULT_MNT=$(buildah mount "$RESULT")

	run_install "bitcoin" "$BUILDAH_LAST_IMAGE" "$RESULT_MNT" "source/prepare-deps.sh"
	buildah unmount "$RESULT" >/dev/null

	VERSION=$(xbuildah run "$RESULT" bitcoind --version | grep 'Bitcoin Core version ' | sed 's#Bitcoin Core version ##g')
	info "VERSION = $VERSION"

	buildah config --label "bitcoind-version=$VERSION" "$RESULT"
}
buildah_cache "btc-build" hash_program_files copy_program_files
### 复制文件 END

info_log ""

RESULT=$(new_container "btc-final" "$BUILDAH_LAST_IMAGE")
buildah config --cmd '/opt/run.sh' --port 8332 --port 8333 --port 8332/udp --port 8333/udp "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/bitcoind "$RESULT"
buildah copy "$RESULT" fs /
buildah commit "$RESULT" gongt/bitcoind
info "Done!"
