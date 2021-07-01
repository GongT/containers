#!/usr/bin/env bash

set -Eeuo pipefail
export TMPDIR="$RUNNER_TEMP"

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.."
# shellcheck source=../common/functions-build-host.sh
source "./common/functions-build-host.sh"

if [[ ${CI+found} != found ]]; then
	die "This script is only for CI"
fi

if [[ ! ${PROJECT_NAME:-} ]]; then
	export -r PROJECT_NAME=$1
fi
cd "$PROJECT_NAME"

export REWRITE_IMAGE_NAME="build.local/dist/${PROJECT_NAME}"

# HASH=$(hash_current_folder)

# EXISTS="$(get_up_to_date_image "$HASH")"

# if [[ "$EXISTS" ]] && [[ ! ${TRIGGER_SKIP_EARLY_DETECT:-} ]]; then
# 	info "$PROJECT_NAME - $HASH - exists [$EXISTS]"
# 	control_ci "set-env" "LAST_COMMITED_IMAGE" "$EXISTS"
# else
bash "./build.sh" || die "Build failed"
# fi

podman rmi "localhost/gongt/${PROJECT_NAME}" &>/dev/null || true # prevent confuse localhost/xxx and docker.io/xxx
