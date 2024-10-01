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
patch --batch --reverse --unified --strip=0 --input=inject.patch
