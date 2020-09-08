#!/usr/bin/env bash

set -Eeuo pipefail

cd "$PROJECT_ROOT"

if ! [[ -e dist/client.alpine ]]; then
	pwsh ./scripts/build.ps1 musl
fi

install -D --verbose --compare --mode=0755 --no-target-directory dist/client.alpine "$INSTALL_TO/wireguard-config-client"
