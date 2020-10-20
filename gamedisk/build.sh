#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

arg_flag FORCE_DNF dnf "force dnf install"
arg_finish "$@"

info "starting..."

### TGTD
STEP="install iscsi-tgtd"
make_base_image_by_dnf "fedora-tgtd" "scsi-target-utils"
### TGTD END

RESULT=$(create_if_not gamedisk-tgtd-result $BUILDAH_LAST_IMAGE)

buildah copy "$RESULT" fs /

buildah config --cmd '/opt/start.sh' --stop-signal SIGINT "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "#MAGIC!" --label name=gongt/gamedisk "$RESULT"
info "settings update..."

buildah commit "$RESULT" gongt/gamedisk
info "Done!"
