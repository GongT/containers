#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

REGISTRY_DOMAIN=${1:-}

export TMPDIR="${RUNNER_TEMP:-$SYSTEM_COMMON_CACHE/tmp}"
mkdir -p "$TMPDIR"
if [[ ! ${GITHUB_ENV:-} ]]; then
	GITHUB_ENV="$TMPDIR/github-env-fake"
fi

if [[ "${CI:-}" ]]; then
	sudo apt install jq gnupg podman buildah mount
fi

sudo cp "../90-myregistry.conf" /etc/containers/registries.conf.d/

JSON=$(gpg --quiet --batch --yes --passphrase "$SECRET_PASSWORD" --decrypt build-secrets.json.gpg)

function query() {
	jq --exit-status --compact-output --monochrome-output --raw-output "$@"
}

function JQ() {
	echo "$JSON" | query "$@"
}

DOCKER_CACHE_CENTER=$(JQ '.cacheCenter')
echo "DOCKER_CACHE_CENTER=${DOCKER_CACHE_CENTER}" >>"$GITHUB_ENV"

echo "SYSTEM_COMMON_CACHE=${SYSTEM_COMMON_CACHE:=$HOME/cache}" >>"$GITHUB_ENV"
mkdir -p "$SYSTEM_COMMON_CACHE"

mkdir -p "$HOME/secrets"
chmod 0700 "$HOME/secrets"
export REGISTRY_AUTH_FILE="$HOME/secrets/auth.json"
echo "REGISTRY_AUTH_FILE=${REGISTRY_AUTH_FILE}" >>"$GITHUB_ENV"

SCRIPT=$(JQ '.dockerCreds[] | "echo " + ("log in to "+.url|@json) + "\npodman login " + ("--username="+.username|@json) + " " + ("--password="+.password|@json) + " " + (.url|@json)')

if [[ "${REGISTRY_DOMAIN:-}" ]]; then
	echo "filter domain $REGISTRY_DOMAIN"
	O_SCRIPT="$SCRIPT"

	FILTER_REG="$(printf '%s' "$REGISTRY_DOMAIN" | sed 's/[.[\(*^$+?{|]/\\&/g')"
	SCRIPT=$(echo "$O_SCRIPT" | grep -E "$FILTER_REG|ghcr\\.io")
fi
echo "$SCRIPT" | bash -xEeuo pipefail

echo 'Done.'
