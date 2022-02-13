#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

export TMPDIR="$RUNNER_TEMP"
source ../common/functions-build.sh

if [[ "${CI:-}" ]] && ! command -v podman &>/dev/null; then
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

echo "::set-output name=DOMAIN_ARRAY::$DOMAIN_ARRAY_JSON"

podman push "$LAST_COMMITED_IMAGE" "docker://$PRIMARY/$PROJECT_NAME:latest"
