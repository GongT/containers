#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_finish "$@"

buildah_cache_start "registry.fedoraproject.org/fedora-minimal"

### 依赖项目
STEP="依赖项目"
PKGS=(socat bash)
hash_download() {
	echo "${PKGS[@]}"
}
do_download() {
	apk_install "$1" "${PKGS[@]}"
	buildah run "$1" rm -rf /etc/rabbitmq
}
buildah_cache "rabbitmq" hash_download do_download
### 依赖项目 END

### 配置文件等
STEP="复制配置文件"
# tar c -v --owner=0 --group=0 --mtime='UTC 2000-01-01' --sort=name "fs" | md5sum
merge_local_fs "rabbitmq"
### 配置文件等 END

info_log ""

buildah_config "rabbitmq" \
	--env=RABBITMQ_CONSOLE_LOG=new \
	--volume=/var/lib/rabbitmq/mnesia \
	"--entrypoint=$(json_array /bin/bash)" \
	--cmd="/opt/start.sh" \
	--stop-signal=SIGUSR1 \
	--author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/rabbitmq

# healthcheck "30s" "5" "curl --insecure https://127.0.0.1:443"

buildah_finalize_image rabbitmq gongt/rabbitmq
