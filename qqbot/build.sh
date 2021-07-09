#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

JAVA_RELEASE="https://download.oracle.com/otn-pub/java/jdk/16.0.1+9/7147401fd7354114ac51ef3e1328291f/jdk-16.0.1_linux-x64_bin.tar.gz"
JAVA_TGZ=$(
	HTTP_COOKIE="oraclelicense=accept-securebackup-cookie" \
		deny_proxy download_file "$JAVA_RELEASE" "$(basename "$JAVA_RELEASE")"
)

### 依赖复制源
STEP=依赖复制源
make_base_image_by_dnf "qqbot" "scripts/requirements.lst"
### 依赖复制源 END

### 复制JAVA
STEP=复制JAVA
check_java() {
	echo "$JAVA_RELEASE"
}
copy_java() {
	local TMPD
	TMPD=$(create_temp_dir java)
	decompression_file "$JAVA_TGZ" 1 "$TMPD"
	buildah copy "$1" "$TMPD" /usr
}
buildah_cache2 "qqbot" check_java copy_java
# ### 复制JAVA END

### 运行MCL安装mirai END
STEP=运行MCL安装mirai
REPO=iTXTech/mirai-console-loader
check_mcl() {
	cat scripts/run-mcl.sh
	http_get_github_release "$REPO"
	RELEASE_URL=$(github_release_asset_download_url_regex '.*\.zip')
	info_note "       * RELEASE_URL=$RELEASE_URL"
}
download_run_mcl() {
	local DOWNLOADED SOURCE_DIRECTORY FILE_NAME="mcl.tar.gz"
	DOWNLOADED=$(perfer_proxy download_file_force "$RELEASE_URL" "$FILE_NAME")
	SOURCE_DIRECTORY="$(create_temp_dir "mcl")"
	extract_zip "$DOWNLOADED" "0" "$SOURCE_DIRECTORY"

	buildah copy "$1" "$SOURCE_DIRECTORY" "/mirai"
	buildah config --workingdir /mirai "$1"
	buildah run --network=host "$1" bash <scripts/run-mcl.sh
}
buildah_cache2 "qqbot" check_mcl download_run_mcl
### 运行MCL安装mirai END
