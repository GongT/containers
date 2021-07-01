#!/usr/bin/env bash

set -Eeuo pipefail
export TMPDIR="$RUNNER_TEMP"

# shellcheck source=../common/functions-build.sh
source ./common/functions-build.sh

JSON=$(gpg --quiet --batch --yes --passphrase "$SECRET_PASSWORD" --decrypt _scripts_/build-secrets.json.gpg)

function JQ() {
	echo "$JSON" | jq --exit-status --compact-output --monochrome-output --raw-output "$@"
}

mapfile -t TARGETS < <(JQ '.publish[]')

for BASE in "${TARGETS[@]}"; do
	CMD=(podman push "$LAST_COMMITED_IMAGE" "docker://$BASE/$PROJECT_NAME:latest")
	control_ci group "${CMD[*]}"
	declare -i TRY=3
	while [[ $TRY -gt 0 ]]; do
		if "${CMD[@]}"; then
			break
		fi
		TRY=$((TRY - 1))
		echo "failed, retry ($TRY)" >&2
	done
	control_ci groupEnd
done
