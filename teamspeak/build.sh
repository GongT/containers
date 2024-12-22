#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE f/force "force re-download binary"
arg_finish "$@"

### Runtime Base
source ../systemd-base-image/include.sh
image_base
### Runtime Base END

### 下载
DOWNLOAD_URL='https://files.teamspeak-services.com/releases/server/3.13.7/teamspeak3-server_linux_amd64-3.13.7.tar.bz2'
_hash_binary() {
	echo "1"
	echo "${DOWNLOAD_URL}"
	# http_get_etag "${DOWNLOAD_URL}"
}
_download_binary() {
	local TGT=$1 DOWNLOADED=
	TMPD=$(create_temp_dir teamspeak)
	DOWNLOADED=$(download_file "$DOWNLOAD_URL")
	decompression_file "$DOWNLOADED" 1 "$TMPD"
	buildah copy "$TGT" "$TMPD" "/opt/server"
	buildah run "$TGT" /usr/bin/bash -c "mv /opt/server/redist/libmariadb.so.2 /usr/lib64"
}
STEP="下载服务器程序"
buildah_cache teamspeak _hash_binary _download_binary
### 下载 END

STEP="复制配置文件"
merge_local_fs "teamspeak"

setup_systemd "teamspeak" \
	enable "REQUIRE=teamspeak3-server.service"

buildah_config "teamspeak" \
	"--volume=/data" \
	"--workingdir=/opt/server"

buildah_finalize_image "teamspeak" gongt/teamspeak
info "Done!"
