#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

source ../_shared/proxy-server-client.sh

### 依赖项目
STEP="安装系统依赖"
DEPS=(bash curl wireguard-tools-wg dnsmasq util-linux iproute2 bind-tools)
make_base_image_by_apk "gongt/alpine-init" "proxyserver" "${DEPS[@]}" <scripts/post-install.sh
### 依赖项目 END

### 复制编译结果
STEP="复制编译结果"
install_build_result "proxyserver" "$PROXY_BUILT_IMAGE" microsocks
### 复制编译结果 END

### 复制配置文件
merge_local_fs "proxyclient"
### 复制配置文件 END

### IANA根域名列表
REAL_DNS_SERVER=127.0.0.1#5353 \
	SAVE_TO="/opt/tlds.conf" \
	source ../_shared/iana-tlds-to-dnsmasq.sh "proxyserver"
### IANA根域名列表 END

STEP="配置镜像信息"
buildah_config "proxyserver" scripts/config.lst

RESULT=$(create_if_not "proxyserver" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/proxyserver-nat
info "Done!"
