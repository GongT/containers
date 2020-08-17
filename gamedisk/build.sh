#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE_DNF dnf "force dnf install"
arg_finish "$@"

info "starting..."

RESULT=$(create_if_not gamedisk-tgtd-result scratch)
RESULT_MNT=$(buildah mount $RESULT)
info "init complete..."

if ! [[ -f "$RESULT_MNT/usr/sbin/tgtd" ]] || [[ -n "$FORCE_DNF" ]]; then
	run_dnf $RESULT "scsi-target-utils"
	buildah run $RESULT systemctl enable tgtd
	info "dnf install complete..."
else
	info "dnf install already complete."
fi

buildah copy $RESULT fs /

buildah config --cmd '/lib/systemd/systemd' "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "GongT" --label name=gongt/gamedisk "$RESULT"
info "settings update..."

buildah commit "$RESULT" gongt/gamedisk
info "Done!"
