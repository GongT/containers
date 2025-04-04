#!/usr/bin/env bash

set -Eeuo pipefail

export MENU_DIR='/data/content/00 目录'
rm -rf "${MENU_DIR}"
mkdir -p "${MENU_DIR}"

mkdir -p "/etc/rslsync"
bash /opt/prepare-start-inner.sh | sed 's/}{/},{/g' | jq >/etc/rslsync/config.json
