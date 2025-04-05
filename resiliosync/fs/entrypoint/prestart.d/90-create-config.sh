#!/usr/bin/env bash

set -Eeuo pipefail

mkdir -p "/etc/rslsync"
grep -vE '^\s*// ' /opt/base-config.jsonc >/etc/rslsync/config.json

if [[ -e "/data/config/profile.sh" ]]; then
	bash /data/config/profile.sh | jq >/tmp/config.data
	jq --slurpfile shared_folders /tmp/config.data '. + {shared_folders: $shared_folders}' \
		</etc/rslsync/config.json \
		>/etc/rslsync/boot.json
	rm -f /tmp/config.data
fi
