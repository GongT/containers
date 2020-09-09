#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "starting..."
RESULT=$(create_if_not bttracker-worker node:alpine)

info "pnpm install..."
pnpm -C app --prod install

buildah copy "$RESULT" app /data/app
info "copy files..."

buildah config --cmd 'node --unhandled-rejections=strict /data/app/lib/main.js' "$RESULT"
buildah config --stop-signal SIGINT "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/bttracker "$RESULT"
info "settings updated..."

buildah commit "$RESULT" gongt/bttracker
info "Done!"
