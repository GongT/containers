#!/usr/bin/env bash

set -Eeuo pipefail

chmod a+w /var/run

if ! [[ -f "/opt/config/$INSTANCE_NAME.json" ]]; then
	echo "{}" >"/opt/config/$INSTANCE_NAME.json"
fi

if [[ -f /opt/data/settings.json ]]; then
	unlink /opt/data/settings.json
fi

sed "s/{instance}/$INSTANCE_NAME/g" </opt/scripts/config.json >/tmp/config.json

jq -s '.[0] * .[1]' /tmp/config.json "/opt/config/$INSTANCE_NAME.json" >/opt/data/settings.json

sed "s/{instance}/$INSTANCE_NAME/g" </opt/scripts/nginx.conf >"/opt/nginx.conf"

chown -R media_rw:users /opt
