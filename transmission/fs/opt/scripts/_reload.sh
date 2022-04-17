#!/usr/bin/env bash

set -Eeuo pipefail

T="/run/nginx/vhost.d/transmission.conf"
cp -v "/opt/scripts/nginx.conf" "$T"
curl --unix /run/sockets/nginx.reload.sock http://_/

if ! [[ -f /opt/config/config.json ]];then
	touch /opt/config/config.json
fi

rm -f /opt/data/settings.json
jq -s '.[0] * .[1]' /opt/scripts/config.json /opt/config/config.json > /opt/data/settings.json
