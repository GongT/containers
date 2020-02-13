#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."
RESULT=$(create_if_not registry-worker registry)


buildah copy "$RESULT" opt /opt
info "files added..."

buildah config --entrypoint '["/bin/sh"]' --cmd '/opt/run.sh' --stop-signal=SIGINT "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "GongT" --label name=gongt/docker-registry "$RESULT"
info "settings updated..."

buildah commit "$RESULT" gongt/docker-registry
info "Done!"
