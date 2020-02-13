#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."
RESULT=$(create_if_not cloud-worker gongt/alpine-init:cn)

cat scripts/build-script.sh | buildah run "$RESULT" sh
info "install complete..."

buildah copy "$RESULT" fs /
info "copy config files complete..."

buildah config --author "GongT <admin@gongt.me>" --created-by "GongT" --label name=gongt/cloud "$RESULT"
info "settings updated..."

buildah commit "$RESULT" gongt/cloud
info "Done!"

