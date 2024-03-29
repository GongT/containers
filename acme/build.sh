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
REPO="acmesh-official/acme.sh"
BRANCH=master
hash_acme() {
	http_get_github_last_commit_id_on_branch "$REPO" "$BRANCH"
	cat scripts/build-acme.sh
}
do_acme() {
	local MNT
	MNT=$(create_temp_dir "acme")

	download_github "$REPO" "$BRANCH"
	download_git_result_copy "$MNT" "$REPO" "$BRANCH"

	buildah run "--volume=$MNT:/mnt" "$1" bash <scripts/build-acme.sh
}
buildah_cache2 "acme" hash_acme do_acme
### 安装acme END

### 复制文件
STEP="复制文件"
merge_local_fs "acme"
### 安装acme END

STEP="配置镜像信息"
buildah_config "acme" --entrypoint "$(json_array /opt/entrypoint.sh)" --stop-signal=SIGINT \
	--volume /opt/data --volume /log --volume /etc/ACME \
	--env "LE_CONFIG_HOME=/opt/data" \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/acme
info "settings updated..."

RESULT=$(create_if_not "acme" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/acme
info "Done!"
