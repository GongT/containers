#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

RESULT=$(create_if_not infra-result gongt/alpine-init)
MNT=$(buildah mount "$RESULT")
info "init compile..."

install_shared_project wireguard-config-client "$MNT/usr/libexec"
info "wireguard client installed..."

buildah run $(use_alpine_apk_cache) $RESULT apk add -U bash curl wireguard-tools-wg
buildah copy $RESULT fs /
info "packages installed..."

buildah config --author "GongT <admin@gongt.me>" --label name=gongt/virtual-gateway "$RESULT"
info "settings update..."

buildah commit "$RESULT" gongt/virtual-gateway
info "Done!"
