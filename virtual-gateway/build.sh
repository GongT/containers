#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

RESULT=$(create_if_not infra-result gongt/alpine-init:latest-cn)

info "init compile..."

buildah run $(use_alpine_apk_cache) $RESULT apk add bash curl wireguard-tools-wg
buildah copy $RESULT fs /
info "packages installed..."

buildah config --author "GongT <admin@gongt.me>" --created-by "GongT" --label name=gongt/virtual-gateway "$RESULT"
info "settings update..."

buildah commit "$RESULT" gongt/virtual-gateway
info "Done!"
