#!/usr/bin/env bash

set -e

CFG=/data/config/config.jsonc
if ! [[ -f $CFG ]]; then
	echo "first run."
	cp /opt/init-config.jsonc "$CFG"
fi

cd /tmp
exec rslsync --nodaemon --config "$CFG" --log /data/log/main.log
