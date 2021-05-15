#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

### 依赖项目
STEP="安装系统依赖"
declare -a DEPS=(ca-certificates bash curl openssl ssmtp)
make_base_image_by_apk gongt/alpine-cn "certbot" "${DEPS[@]}"
### 依赖项目 END

### 安装acme
STEP="安装acme.sh"
REPO="Neilpang/acme.sh"
BRANCH="master"
hash_download() {
	cat scripts/install.sh
	http_get_github_last_commit_id_on_branch "$REPO" "$BRANCH"
}
copy_acme() {
	local TMPSRC
	download_github "$REPO" "$BRANCH"
	TMPSRC=$(create_temp_dir "acme-downloaded")

	download_git_result_copy "$TMPSRC" "$REPO" "$BRANCH"
	buildah run \
		"--volume=$TMPSRC:/opt/acme.sh.source" \
		"$1" \
		bash <scripts/install.sh
}
buildah_cache2 "certbot" hash_download copy_acme
### 安装acme END

### 复制文件
STEP="复制文件"
hash_files() {
	hash_path opt
}
copy_fs() {
	buildah copy "$1" opt /opt
}
buildah_cache2 "certbot" hash_files copy_fs
### 安装acme END

STEP="配置镜像信息"
buildah_config "certbot" --entrypoint '["/bin/bash","/opt/entrypoint.sh"]' --stop-signal=SIGINT \
	--volume /config --volume /log --volume /etc/letsencrypt \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/certbot-dns
info "settings updated..."

RESULT=$(create_if_not "certbot" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/certbot-dns
info "Done!"
