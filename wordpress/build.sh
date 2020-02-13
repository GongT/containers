#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."
RESULT=$(create_if_not wordpress-worker gongt/alpine-init:cn)

buildah copy "$RESULT" fs /
info "copy files complete..."

cat scripts/build-script.sh | buildah run "$RESULT" sh
info "install complete..."

buildah config --author "GongT <admin@gongt.me>" --created-by "GongT" --label name=gongt/wordpress "$RESULT"
info "settings updated..."

buildah commit "$RESULT" gongt/wordpress
info "Done!"

