#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

### 安装依赖
STEP=安装依赖
make_base_image_by_dnf "qqbot" "scripts/requirements.lst"
### 安装依赖 END

### 运行MCL安装mirai END
STEP=运行MCL安装mirai
REPO=iTXTech/mirai-console-loader
check_mcl() {
	cat scripts/run-mcl.sh
	http_get_github_release_id "mamoe/mirai"
	http_get_github_release "$REPO"
	RELEASE_URL=$(github_release_asset_download_url_regex '.*\.zip')
	info_note "       * RELEASE_URL=$RELEASE_URL"
}
download_run_mcl() {
	local DOWNLOADED SOURCE_DIRECTORY FILE_NAME="mcl.tar.gz"
	DOWNLOADED=$(perfer_proxy download_file "$RELEASE_URL" "$FILE_NAME")
	SOURCE_DIRECTORY="$(create_temp_dir "mcl")"
	extract_zip "$DOWNLOADED" "0" "$SOURCE_DIRECTORY"

	# local DATA
	# if [[ -e "$SOURCE_DIRECTORY/config.json" ]]; then
	# 	DATA=$(<"$SOURCE_DIRECTORY/config.json")
	# else
	# 	DATA='{}'
	# fi
	# DATA=$(echo "$DATA" | jq --arg URL "https://github.com/project-mirai/mirai-repo-mirror" '.mirai_repo = $URL')
	# DATA=$(echo "$DATA" | jq --arg URL "https://repo1.maven.org/maven2/" '.maven_repo = [$URL]')
	# echo "$DATA" >"$SOURCE_DIRECTORY/config.json"

	buildah copy "$1" "$SOURCE_DIRECTORY" "/mirai"
	buildah config --workingdir /mirai "$1"
	buildah run --network=host "$1" bash <scripts/run-mcl.sh
}
buildah_cache2 "qqbot" check_mcl download_run_mcl
### 运行MCL安装mirai END

### 运行MCL安装mirai END
STEP="下载api-http模块"
REPO="project-mirai/mirai-api-http"
check_mcl() {
	http_get_github_release "$REPO"
	RELEASE_URL=$(github_release_asset_download_url_regex '^.*\.jar$')
	info_note "       * RELEASE_URL=$RELEASE_URL"
}
download_run_mcl() {
	local DOWNLOADED FILE_NAME
	FILE_NAME=$(basename "$RELEASE_URL")
	DOWNLOADED=$(perfer_proxy download_file "$RELEASE_URL" "$FILE_NAME")

	buildah copy "$1" "$DOWNLOADED" "/mirai/plugins"
}
buildah_cache2 "qqbot" check_mcl download_run_mcl
### 运行MCL安装mirai END

STEP=复制文件
merge_local_fs "qqbot"

STEP=配置容器
buildah_config "qqbot" --cmd "/mirai/start.sh" --stop-signal=SIGINT \
	--volume /mirai/config --volume /mirai/data --volume /mirai/logs --volume /mirai/bots \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/acme

RESULT=$(create_if_not "qqbot" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/qqbot
info "Done!"
