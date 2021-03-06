#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."
RESULT=$(create_if_not mariadb-worker gongt/alpine-init)

info "installing..."
cat scripts/build-script.sh | buildah run $(use_alpine_apk_cache) "$RESULT" -- sh
info "install complete..."

buildah copy "$RESULT" fs /

buildah config "$RESULT"
buildah config --cmd '/sbin/init' "$RESULT"
buildah config --volume /var/lib/mysql --volume /var/log --port 3306 --stop-signal SIGINT "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/mariadb "$RESULT"
info "settings updated..."

buildah commit "$RESULT" gongt/mariadb
info "Done!"
