#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

source ../_shared/proxy-server-client.sh

### 依赖项目
STEP="安装系统依赖"
DEPS=(bash wireguard-tools-wg dnsmasq privoxy)
make_base_image_by_apk "gongt/alpine-init" "proxyclient" "${DEPS[@]}" <scripts/post-install.sh
### 依赖项目 END

### 复制编译结果
STEP="复制编译结果"
install_build_result "proxyclient" "$PROXY_BUILT_IMAGE" udp2raw
### 复制编译结果 END

### 复制配置文件
merge_local_fs "proxyclient"
### 复制配置文件 END

### IANA根域名列表
REAL_DNS_SERVER=10.233.233.1 \
	source ../_shared/iana-tlds-to-dnsmasq.sh "proxyclient"
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
