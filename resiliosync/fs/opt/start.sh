#!/usr/bin/env bash

set -e

if ! [[ -f "/data/config/config.json" ]]; then
	echo "first run."
	cp /opt/init-config.jsonc /data/config/config.jsonc
fi

cd /tmp
exec rslsync --nodaemon --config /data/config/config.jsonc --log /data/log/main.log
