#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.."
# shellcheck source=../common/functions-build-host.sh
source "./common/functions-build-host.sh"

if [[ ${CI+found} != found ]]; then
	die "This script is only for CI"
fi

declare -r NAME=$1
cd "$NAME"

declare -rx REWRITE_IMAGE_NAME="docker.io/gongt/${NAME}"

HASH=$(hash_current_folder)

EXISTS="$(get_up_to_date_image "$HASH")"

if [[ "$EXISTS" ]] && [[ ! ${TRIGGER_SKIP_EARLY_DETECT:-} ]]; then
	info "$NAME - $HASH - exists [$EXISTS]"
	control_ci "set-env" "LAST_COMMITED_IMAGE" "$EXISTS"
else
	bash "./build.sh" || die "Build failed"
fi

podman rmi "localhost/gongt/${NAME}" &>/dev/null || true
