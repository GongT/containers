#!/usr/bin/env bash

set -Eeuo pipefail

export MENU_DIR='/data/content/00 目录'
rm -rf "${MENU_DIR}"
mkdir -p "${MENU_DIR}"

mkdir -p "/etc/rslsync"
bash /opt/prepare-start-inner.sh | sed 's/}{/}{/g' | jq >/tmp/config.data

grep -vE '^\s*// ' /opt/base-config.jsonc \
	| jq --slurpfile shared_folders /tmp/config.data '. + {shared_folders: $shared_folders}' \
		>/etc/rslsync/config.json

rm -f /tmp/config.data
