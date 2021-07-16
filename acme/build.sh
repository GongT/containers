#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

### 依赖项目
STEP="安装系统依赖"
declare -a DEPS=(ca-certificates bash curl openssl ssmtp)
make_base_image_by_apk alpine "acme" "${DEPS[@]}"
### 依赖项目 END

### 安装acme
STEP="安装acme.sh"
download_and_build_github "acme" acme "acmesh-official/acme.sh" master
### 安装acme END

### 复制文件
STEP="复制文件"
hash_files() {
	hash_path opt
}
copy_fs() {
	buildah copy "$1" opt /opt
}
buildah_cache2 "acme" hash_files copy_fs
### 安装acme END

STEP="配置镜像信息"
buildah_config "acme" --entrypoint "$(json_array /opt/entrypoint.sh)" --stop-signal=SIGINT \
	--volume /config --volume /log --volume /etc/ACME \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/acme
info "settings updated..."

RESULT=$(create_if_not "acme" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/acme
info "Done!"
