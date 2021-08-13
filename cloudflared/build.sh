#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

unset PROXY

arg_finish "$@"

### 依赖项目
STEP="安装依赖项目"
make_base_image_by_dnf "cloudflared" scripts/requirements.lst
### 依赖项目 END

### 安装cloudflared
STEP="安装cloudflared"
REPO="cloudflare/cloudflared"
RELEASE_URL=
hash_download() {
	cat scripts/build-acme.sh
	http_get_github_release_id "$REPO"
	RELEASE_URL=$(github_release_asset_download_url cloudflared-linux-amd64)
}
do_download() {
	local TGT=$1 DOWNLOADED FILE_NAME="cloudflared"
	DOWNLOADED=$(download_file_force "$RELEASE_URL" "$FILE_NAME")
	buildah copy "$TGT" "$DOWNLOADED" "/usr/bin/cloudflared"
	buildah run "$TGT" chmod 0777 "/usr/bin/cloudflared"
}
buildah_cache2 "cloudflared" hash_download do_download
### 安装cloudflared END

### 配置文件等
STEP="复制配置文件"
merge_local_fs "cloudflared"
### 配置文件等 END

info_log ""

buildah_config "cloudflared" --entrypoint "$(json_array /opt/start.sh)" \
	--volume /root/.cloudflared \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/cloudflared

# healthcheck "30s" "5" "curl --insecure https://127.0.0.1:443"

RESULT=$(create_if_not cloudflared "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/cloudflared
