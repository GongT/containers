#!/usr/bin/env bash

set -Eeuo pipefail
export TMPDIR="$RUNNER_TEMP"

if [[ "${CI:-}" ]]; then
	sudo apt install jq gnupg podman buildah
fi

JSON=$(gpg --quiet --batch --yes --passphrase "$SECRET_PASSWORD" --decrypt _scripts_/build-secrets.json.gpg)

function query() {
	jq --exit-status --compact-output --monochrome-output --raw-output "$@"
}

function JQ() {
	echo "$JSON" | query "$@"
}

DOCKER_CACHE_CENTER=$(JQ '.cacheCenter')
echo "DOCKER_CACHE_CENTER=${DOCKER_CACHE_CENTER}" >>"$GITHUB_ENV"

echo "SYSTEM_COMMON_CACHE=${SYSTEM_COMMON_CACHE:=$HOME/cache}" >>"$GITHUB_ENV"
mkdir "$SYSTEM_COMMON_CACHE"

mkdir -p "$HOME/secrets"
chmod 0700 "$HOME/secrets"
export REGISTRY_AUTH_FILE="$HOME/secrets/auth.json"
echo "REGISTRY_AUTH_FILE=${REGISTRY_AUTH_FILE}" >>"$GITHUB_ENV"

JQ '.dockerCreds[] | "echo " + ("log in to "+.url|@json) + "\npodman login " + ("--username="+.username|@json) + " " + ("--password="+.password|@json) + " " + (.url|@json)' \
	| bash

echo 'Done.'
