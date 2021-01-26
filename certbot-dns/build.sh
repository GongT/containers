#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

### 依赖项目
STEP="安装系统依赖"
declare -a DEPS=(ca-certificates bash curl wget openssl)
make_base_image_by_apt gongt/alpine-cn "certbot" "${DEPS[@]}"
### 依赖项目 END

### 安装acme
STEP="安装acme.sh"
hash_acme() {
	fast_hash_path opt/acme.sh
}
copy_acme() {
	buildah add "$1" opt /opt
	buildah run "$1" bash <scripts/install.sh
}
buildah_cache2 "certbot" hash_acme copy_acme
### 安装acme END

STEP="配置镜像信息"
buildah_config "certbot" --entrypoint '["/bin/bash"]' --cmd '/opt/init.sh' --stop-signal=SIGINT \
	--volume /config --volume /etc/letsencrypt \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/certbot-dns
info "settings updated..."

RESULT=$(create_if_not "certbot" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/certbot-dns
info "Done!"
