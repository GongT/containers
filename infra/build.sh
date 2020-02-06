#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

RESULT=$(create_if_not infra-result gongt/alpine-init:cn)

info "init compile..."

buildah run $RESULT apk --no-cache add bash curl wireguard-tools-wg
buildah copy $RESULT etc /etc
info "packages installed..."

buildah config --cmd '/sbin/init' "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "GongT" --label name=gongt/infra "$RESULT"
info "settings update..."

buildah commit "$RESULT" gongt/infra
info "Done!"
