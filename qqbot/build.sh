#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

### 安装依赖
STEP=安装依赖
dnf_use_environment
dnf_install_step "qqbot" "scripts/requirements.lst"
### 安装依赖 END

### 运行MCL安装mirai END
STEP=运行MCL安装mirai
REPO=iTXTech/mirai-console-loader
check_mcl() {
	cat scripts/run-mcl.sh
	http_get_github_unstable_release_id "mamoe/mirai"
	http_get_github_release "$REPO"
	RELEASE_URL=$(github_release_asset_download_url_regex '.*\.zip')
	info_note "       * RELEASE_URL=$RELEASE_URL"
}
download_run_mcl() {
	local DOWNLOADED SOURCE_DIRECTORY
	DOWNLOADED=$(perfer_proxy download_file_force "$RELEASE_URL")
	SOURCE_DIRECTORY="$(create_temp_dir "mcl")"
	extract_zip "$DOWNLOADED" "0" "$SOURCE_DIRECTORY"

	local DATA
	if [[ -e "$SOURCE_DIRECTORY/config.json" ]]; then
		DATA=$(<"$SOURCE_DIRECTORY/config.json")
	else
		DATA='{}'
	fi
	DATA=$(echo "$DATA" | jq --arg URL "https://raw.githubusercontent.com/project-mirai/mirai-repo-mirror/master" '.mirai_repo = $URL')
	DATA=$(echo "$DATA" | jq --arg URL "https://repo1.maven.org/maven2" '.maven_repo = [$URL]')
	DATA=$(echo "$DATA" | jq '.disabled_modules = ["announcement"]')
	echo "$DATA" >"$SOURCE_DIRECTORY/config.json"

	buildah copy "$1" "$SOURCE_DIRECTORY" "/mirai"
	buildah config --workingdir /mirai "$1"
	buildah run --network=host "$1" bash <scripts/run-mcl.sh
}
buildah_cache "qqbot" check_mcl download_run_mcl
### 运行MCL安装mirai END

STEP=复制文件
merge_local_fs "qqbot"

STEP=配置容器
buildah_config "qqbot" --cmd "/mirai/start.sh" --stop-signal=SIGINT \
	--volume /mirai/config --volume /mirai/data --volume /mirai/logs --volume /mirai/bots \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/acme

buildah_finalize_image "qqbot" gongt/qqbot
info "Done!"
