#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_finish "$@"

source ../_shared/php/alpine.sh "dandan-api" curl

STEP="复制文件系统"
merge_local_fs "dandan-api"

STEP="更新配置"
buildah_config "dandan-api" --entrypoint '/bin/bash' --cmd '/data/start.sh'

RESULT=$(create_if_not "dandan-api" "$BUILDAH_LAST_IMAGE")
buildah commit "$RESULT" gongt/dandan-api
