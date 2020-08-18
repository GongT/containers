#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE_DNF dnf "force dnf install"
arg_finish

info "starting..."

RESULT=$(create_if_not samba-result scratch)
RESULT_MNT=$(buildah mount $RESULT)
info "init complete..."

if [[ ! -e "$RESULT_MNT/usr/bin/bash" ]] || [[ -n "$FORCE_DNF" ]]; then
	run_dnf $RESULT systemd bash samba samba-common-tools iproute iputils passwd
	info "dnf install complete..."
else
	info "dnf install already complete."
fi

cat "scripts/prepare.sh" | buildah run $RESULT bash
buildah copy $RESULT fs /

buildah config --cmd "/lib/systemd/systemd systemd.show_status systemd.log_target=console" "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "GongT" --label name=gongt/samba "$RESULT"
info "settings update..."

buildah commit "$RESULT" gongt/samba
info "Done!"
