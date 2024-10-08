#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

STEP="安装依赖"
make_base_image_by_apk "alpine:edge" "mqtt" bash mosquitto mosquitto-clients curl

### 复制文件
STEP="复制文件"
hash_fs_files() {
	hash_path fs
}
copy_fs_files() {
	buildah copy "$1" fs /
}
buildah_cache mqtt hash_fs_files copy_fs_files
### 复制文件 END

buildah_config "mqtt" \
	--env "PATH=/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
	--entrypoint '["/bin/bash"]' \
	--cmd '/opt/start.sh' \
	--volume /data --volume /settings \
	--author "GongT <admin@gongt.me>" \
	--created-by "#MAGIC!" \
	--label name=gongt/mqtt-broker

buildah_finalize_image "mqtt" gongt/mqtt-broker
