#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."
RESULT=$(create_if_not mariadb-worker gongt/alpine-init:latest-cn)

info "installing..."
cat scripts/build-script.sh | buildah run "$RESULT" -- sh
info "install complete..."

buildah copy "$RESULT" fs /

buildah config "$RESULT"
buildah config --entrypoint '["/bin/sh", "-c"]' --cmd '"env ; sleep 1 ; /sbin/init ; RET=$? ; echo \"Exit code $RET\" ; exit $?"' "$RESULT"
buildah config --volume /var/lib/mysql --volume /var/log --port 3306 "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "GongT" --label name=gongt/mariadb "$RESULT"
info "settings updated..."

buildah commit "$RESULT" gongt/mariadb
info "Done!"
