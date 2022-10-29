#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

BUILDAH_LAST_IMAGE="node:alpine"

STEP="复制应用文件并安装依赖"
mkdir -p "$SYSTEM_COMMON_CACHE/nodejs/npm"
merge_local_fs "bttracker" "--volume=$SYSTEM_COMMON_CACHE/nodejs/npm:/root/nodejs/.npm" scripts/npm-install.sh

buildah_config "bttracker" --entrypoint '' --cmd 'node --unhandled-rejections=strict /data/app/lib/main.js' \
	--stop-signal SIGINT --volume /data/store \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!"
info "settings updated..."

RESULT=$(create_if_not "bttracker" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/bttracker
info "Done!"
