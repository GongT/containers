#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."

RESULT=$(create_if_not fiber-host-result registry.gongt.me/gongt/init)

info "init compile..."

buildah run $(use_alpine_apk_cache) $RESULT apk add -U dnsmasq bash iperf3
buildah copy "$RESULT" fs /
info "packages installed..."

buildah config --author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/fiberhost "$RESULT"
info "settings update..."

buildah commit "$RESULT" gongt/fiberhost
info "Done!"
