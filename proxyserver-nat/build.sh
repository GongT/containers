#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

### 编译microsocks
STEP="安装microsocks编译依赖"
DEPS=(bash make gcc musl-dev)
make_base_image_by_apk "gongt/alpine-init" "proxyserver-nat.microsocks" "${DEPS[@]}"

STEP="下载并编译microsocks"
CURRENT_COMMIT_ID=
function hash_master() {
	CURRENT_COMMIT_ID=$(http_get_github_last_commit_id "rofl0r/microsocks")
	{
		echo "$CURRENT_COMMIT_ID"
		cat scripts/build-microsocks.sh
	}
}
function build_microsocks() {
	local DOWNFILE COMPILE_SOURCE_DIRECTORY BUILDER=$1
	DOWNFILE=$(download_file "https://github.com/rofl0r/microsocks/archive/master.tar.gz" "microsocks.$CURRENT_COMMIT_ID.tar.gz")
	COMPILE_SOURCE_DIRECTORY=$(decompression_file_source microsocks "$DOWNFILE" 1)
	run_compile "microsocks" "$BUILDER" "scripts/build-microsocks.sh"
}
buildah_cache2 "proxyserver-nat.microsocks" hash_master build_microsocks
MICROSOCKS_IMAGE=$BUILDAH_LAST_IMAGE
### 编译microsocks END

### 依赖项目
STEP="安装系统依赖"
DEPS=(bash curl wireguard-tools-wg dnsmasq util-linux iproute2 bind-tools)
make_base_image_by_apk "gongt/alpine-init" "proxyserver-nat" "${DEPS[@]}" <scripts/post-install.sh
### 依赖项目 END

### 编译udp2raw
TMPF="/tmp/build.udp2raw"
collect_temp_file "$TMPF"
install_shared_project udp2raw "$TMPF"
### 编译udp2raw END

### 编译结果
STEP="复制编译结果"
test_changes() {
	echo "$MICROSOCKS_IMAGE"
	hash_path "$TMPF"
	fast_hash_path "$(pwd)/fs"
}
copy_files() {
	local CTR=$1 MNT
	MNT=$(buildah mount "$CTR")
	info_log "      copy microsocks"
	run_install microsocks "$MICROSOCKS_IMAGE" "$MNT" <<-'INSTALL_SCRIPT'
		cp -r . -T "$INSTALL_TARGET"
	INSTALL_SCRIPT

	info_log "      copy udp2raw"
	install -m 0755 "$TMPF/udp2raw" "$MNT/usr/bin"

	info_log "      copy /fs"
	cp -r "$(pwd)/fs" -T "$MNT"
}
buildah_cache2 "proxyserver-nat" test_changes copy_files
### 编译结果 END

### IANA根域名列表
REAL_DNS_SERVER=127.0.0.1#5353 \
	SAVE_TO="/opt/tlds.conf" \
	source ../_shared_projects/dns/iana-tlds-to-dnsmasq.sh "proxyserver-nat"
### IANA根域名列表 END

STEP="配置镜像信息"
buildah_config "proxyserver-nat" scripts/config.lst

RESULT=$(create_if_not "proxyserver-nat" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/proxyserver-nat
info "Done!"
