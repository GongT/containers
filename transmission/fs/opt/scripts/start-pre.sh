#!/usr/bin/env bash

set -Eeuo pipefail

chmod a+w /var/run

if ! [[ -f /opt/config/config.json ]]; then
	echo "{}" >/opt/config/config.json
fi

if [[ -f /opt/data/settings.json ]]; then
	rm -f /opt/data/settings.json
fi

jq -s '.[0] * .[1]' /opt/scripts/config.json /opt/config/config.json >/opt/data/settings.json

touch /data/invalid
