#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE_DNF dnf "force dnf install"
arg_finish "$@"

### 依赖项目
STEP="安装依赖项目"
dnf_use_environment
dnf_install_step "HA" scripts/compile.lst scripts/post-dnf.sh
### 依赖项目 END

### HA (python pip)
STEP="安装HA"
hash_file() {
	cat scripts/install.sh
}
run_install() {
	buildah config "--env=PATH=/hass/python/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" "$1"
	buildah run --network=host "--volume=$SYSTEM_COMMON_CACHE/pip:/var/cache/pip" "$1" bash <scripts/install.sh
}
buildah_cache HA hash_file run_install
### HA END
exit 1

STEP="安装HACS"
REPO="hacs/integration"
get_download() {
	http_get_github_release_id "$REPO"
}
do_download() {
	local URL DOWNLOADED
	URL=$(github_release_asset_download_url "hacs.zip")
	DOWNLOADED=$(perfer_proxy download_file "$URL" "$(__github_release_json_id).zip")
	buildah copy "$1" "$DOWNLOADED" "/plugins/hacs.zip"
}
buildah_cache HA get_download do_download

STEP="复制文件系统"
merge_local_fs HA

buildah_config HA \
	--author "GongT <admin@gongt.me>" \
	--created-by "#MAGIC!" \
	--label name=gongt/homeassistant \
	--env DISABLE_JEMALLOC=YES
info "settings update..."

buildah_finalize_image "homeassistant" gongt/homeassistant
info "Done!"
