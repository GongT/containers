#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

### 依赖项目
STEP="安装系统依赖"
make_base_image_by_apt gongt/alpine-init "infra-build" bash curl wireguard-tools-wg
### 依赖项目 END

### 下载
REPO="GongT/wireguard-config-distribute"
RELEASE_BINARY_URL="https://github.com/$REPO/releases/download/latest/client.alpine"
STEP="下载 wireguard-config-client"
hash_wireguard() {
	http_get_github_release_id "GongT/wireguard-config-distribute"
}
download_wireguard() {
	local RESULT MNT DOWNLOADED VERSION
	RESULT=$(new_container "$1" "$BUILDAH_LAST_IMAGE")
	MNT=$(buildah mount "$RESULT")
	DOWNLOADED=$(download_file "$RELEASE_BINARY_URL" "wg-client.$WANTED_HASH")

	install -D --verbose --compare --mode=0755 --no-target-directory "$DOWNLOADED" "$MNT/usr/libexec/wireguard-config-client"

	VERSION=$(xbuildah run "$RESULT" sh -c '/usr/libexec/wireguard-config-client -V' 2>&1)
	info "VERSION = $VERSION"

	buildah config --label "client-version=$VERSION" "$RESULT"
}
buildah_cache "infra-build" hash_wireguard download_wireguard
### 下载 END

RESULT=$(new_container "infra-result" "$BUILDAH_LAST_IMAGE")
buildah copy "$RESULT" fs /
buildah config --author "GongT <admin@gongt.me>" --label name=gongt/virtual-gateway "$RESULT"
info "settings update..."

buildah commit "$RESULT" gongt/virtual-gateway
info "Done!"
