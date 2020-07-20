#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."
WORK=$(create_if_not blog-worker alpine)
RESULT=$(create_if_not blog-result alpine)

info "install..."
buildah run "$RESULT" apk --no-cache add nodejs
info "install complete..."

cat scripts/build-script.sh | buildah run "$WORK" sh
info "build complete..."

W_MNT=$(buildah mount "$WORK")
R_MNT=$(buildah mount "$RESULT")
rm -rf "$R_MNT/data"
cp -r "$W_MNT/data/app" -T "$R_MNT/data"
rm -rf "$R_MNT/data/.git"
buildah copy "$RESULT" fs /
info "copy files complete..."

buildah config --cmd 'sh /opt/lifecycle.sh' --stop-signal=SIGINT "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "GongT" --label name=gongt/hexo "$RESULT"
info "settings updated..."

buildah commit "$RESULT" gongt/hexo
info "Done!"
