#!/usr/bin/env bash
set -Eeuo pipefail

function require_mountpoint() {
	if ! mountpoint "$1"; then
		exit 1
	fi
}

require_mountpoint /home/qq/.config/QQ
require_mountpoint /opt/loader_data
chown qq:qq /home/qq/.config/QQ \
	/home/qq/.config \
	/home/qq/.cache \
	/home/qq \
	/opt/loader_data
cd /opt

LOADER_MAIN=/opt/QQ/resources/app/app_launcher/index.js
CONTENT=$(<"${LOADER_MAIN}")
if [[ $CONTENT == *"successful patched"* ]]; then
	echo "loader ${LOADER_MAIN} already patched."
	exit 0
fi

echo "patching loader: ${LOADER_MAIN}"
{
	echo "require('/opt/loader');"
	echo "### successful patched"
	echo "${CONTENT}"
} >"${LOADER_MAIN}"
