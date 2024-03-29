#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

export TMPDIR="$RUNNER_TEMP"
BASE=$1

source ../common/functions-build.sh

JSON=$(gpg --quiet --batch --yes --passphrase "$SECRET_PASSWORD" --decrypt build-secrets.json.gpg)

function JQ() {
	echo "$JSON" | jq --exit-status --compact-output --monochrome-output --raw-output "$@"
}

PRIMARY=$(JQ '.publish[0]')
control_ci group "pull from $PRIMARY"
podman pull "docker://$PRIMARY/$PROJECT_NAME:latest"
control_ci groupEnd

DOMAIN=$(JQ '.publish[] | select(startswith($base))' --arg base "$BASE")
CMD=(podman push "$PRIMARY/$PROJECT_NAME:latest" "docker://$DOMAIN/$PROJECT_NAME:latest")

declare -i TRY=3
while [[ $TRY -gt 0 ]]; do
	control_ci group "$TRY: ${CMD[*]}"
	if "${CMD[@]}"; then
		control_ci groupEnd
		echo "complete." >&2
		exit 0
	fi
	control_ci groupEnd
	TRY=$((TRY - 1))
	echo "failed, retry" >&2
done

echo "all failed" >&2
exit 1
