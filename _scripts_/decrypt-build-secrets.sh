#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

PASSWORD="$1"

echo "encrypt using $PASSWORD"
gpg --quiet --batch --yes --passphrase "$PASSWORD" --decrypt build-secrets.json.gpg > build-secrets.json
