#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

REGISTRY_DOMAIN=${1-}

export TMPDIR="${RUNNER_TEMP:-$SYSTEM_COMMON_CACHE/tmp}"
mkdir -p "$TMPDIR"
if [[ ! ${GITHUB_ENV-} ]]; then
	GITHUB_ENV="$TMPDIR/github-env-fake"
fi

if [[ "${CI-}" ]]; then
	if command -v dnf &>/dev/null; then
		DIVE_VERSION=$(curl -sL "https://api.github.com/repos/wagoodman/dive/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
		curl -OL "https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.rpm"
		dnf install -y --nodocs --setopt=install_weak_deps=False "dive_${DIVE_VERSION}_linux_amd64.rpm" jq gnupg podman buildah skopeo wget
	else
		sudo apt-get update
		sudo apt-get -y install jq gnupg podman
	fi
fi

# sudo cp "./_scripts_/80-myregistry.conf" /etc/containers/registries.conf.d/

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

export REGISTRY_AUTH_FILE="/etc/containers/auth.json"
echo "REGISTRY_AUTH_FILE=${REGISTRY_AUTH_FILE}" >>"$GITHUB_ENV"

SCRIPT=$(JQ '.dockerCreds[] | "echo " + ("log in to "+.url|@json) + "\npodman login " + ("--username="+.username|@json) + " " + ("--password="+.password|@json) + " " + (.url|@json)')

if [[ "${REGISTRY_DOMAIN-}" ]]; then
	echo "filter domain $REGISTRY_DOMAIN"
	O_SCRIPT="$SCRIPT"

	FILTER_REG="$(printf '%s' "$REGISTRY_DOMAIN" | sed 's/[.[\(*^$+?{|]/\\&/g')"
	SCRIPT=$(echo "$O_SCRIPT" | grep -E "$FILTER_REG|ghcr\\.io")
fi
echo "$SCRIPT" | bash -xEeuo pipefail

echo 'Done.'
