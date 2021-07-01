#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

PASSWORD=$(jq -cr '.self_password' <build-secrets.json)

echo "encrypt using $PASSWORD"
gpg --quiet --batch --yes --symmetric --cipher-algo AES256 --passphrase "$PASSWORD" build-secrets.json
