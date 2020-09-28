#!/usr/bin/env bash

set -Eeuo pipefail

cd "$PROJECT_ROOT"

URL=$(< "URL.txt")
FILE=$(download_file "$URL" wireguard-config-client-linux-x64)

install -D --verbose --compare --mode=0755 --no-target-directory "$FILE" "$INSTALL_TO/wireguard-config-client"
