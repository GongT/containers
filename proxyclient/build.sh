#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

### 依赖项目
STEP="安装系统依赖"
DEPS=(bash wireguard-tools-wg dnsmasq privoxy)
make_base_image_by_apt "gongt/alpine-init" "proxyclient" "${DEPS[@]}" <scripts/post-install.sh
### 依赖项目 END

### 编译udp2raw
TMPF="/tmp/build.udp2raw"
collect_temp_file "$TMPF"
install_shared_project udp2raw "$TMPF"
STEP="复制编译结果"
test_changes() {
	hash_path "$TMPF"
	fast_hash_path "$(pwd)/fs"
}
copy_files() {
	local CTR=$1 MNT
	MNT=$(buildah mount "$CTR")
	info_log "      copy udp2raw"
	install -m 0755 "$TMPF/udp2raw" "$MNT/usr/bin"

	info_log "      copy /fs"
	cp -r "$(pwd)/fs" -T "$MNT"
}
buildah_cache2 "proxyclient" test_changes copy_files
### 编译udp2raw END

### IANA根域名列表
source ../_shared_projects/dns/iana-tlds-to-dnsmasq.sh "proxyclient"
### IANA根域名列表 END

STEP="配置镜像信息"
buildah_config "proxyclient" \
	--author "GongT <admin@gongt.me>" \
	--created-by "#MAGIC!" \
	--label name=gongt/proxyclient
info "settings updated..."

RESULT=$(create_if_not "proxyclient" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/proxyclient
info "Done!"
