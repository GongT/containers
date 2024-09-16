#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

export TMPDIR="$RUNNER_TEMP"
source ../common/package/include.sh

if [[ "${CI-}" ]] && ! command -v podman &>/dev/null; then
	sudo apt install podman
fi

JSON=$(gpg --quiet --batch --yes --passphrase "$SECRET_PASSWORD" --decrypt build-secrets.json.gpg)

function query() {
	jq --exit-status --compact-output --monochrome-output --raw-output "$@"
}

function JQ() {
	echo "$JSON" | query "$@"
}

PRIMARY=$(JQ '.publish[0]')
mapfile -t URL_ARRAY < <(JQ '.publish[1:][]')
DOMAIN_ARRAY=()

echo "publish to:"
for URL in "${URL_ARRAY[@]}"; do
	echo " * $URL"
	split_url_domain_path "$URL"
	DOMAIN_ARRAY+=("$DOMAIN")
	echo "   -> $DOMAIN"
done

DOMAIN_ARRAY_JSON=$(query -n '$ARGS.positional' --args "${DOMAIN_ARRAY[@]}")
echo "domain array: $DOMAIN_ARRAY_JSON"

echo "DOMAIN_ARRAY=$DOMAIN_ARRAY_JSON" >>"$GITHUB_OUTPUT"

# echo "::group::DIVE" >&2
# dive "$LAST_BUILT_IMAGE_ID" --source podman
# echo "::endgroup::" >&2

echo "publish to primary: $PRIMARY/$PROJECT_NAME:latest"
xpodman push "$LAST_BUILT_IMAGE_ID" "docker://$PRIMARY/$PROJECT_NAME:latest"
