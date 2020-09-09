#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_finish "$@"

info "starting..."
RESULT=$(create_if_not factorio-worker scratch)
RESULT_MNT=$(buildah mount $RESULT)
info "result image prepared..."

if [[ ! -e "$RESULT_MNT/usr/bin/sed" ]]; then
	run_dnf $RESULT glibc sed
	info "dnf install complete..."
else
	info "dnf install already complete."
fi

FILE=$(download_file "https://www.factorio.com/get-download/stable/headless/linux64" factorio.tar.xz)
decompression_file "$FILE" 1 "$RESULT_MNT/opt/factorio"
buildah umount "$RESULT"

buildah copy $RESULT fs /
info "result files copy complete..."

buildah config --cmd '/opt/scripts/start.sh' --port 34197 --stop-signal SIGINT "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/factorio "$RESULT"
info "settings update..."

buildah commit "$RESULT" gongt/factorio
info "Done!"
