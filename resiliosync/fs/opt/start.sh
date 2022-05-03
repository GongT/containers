#!/usr/bin/env bash

set -Eeuo pipefail

hjson -j /opt/init-config.jsonc >/tmp/a.json
jq --null-input --join-output --monochrome-output '{"listening_port": $ARGS.named.v|tonumber, "webui": {"listen": ("0.0.0.0:"+$ARGS.named.u) } }' --arg v "$PORT" --arg u "$UIPORT" >/tmp/b.json

jq --join-output --monochrome-output --slurp '.[0] * .[1]' /tmp/a.json /tmp/b.json >/tmp/config-ui.json

echo -e "0\n0" >/data/state/debug.txt

if [[ -e "/data/config/profile.sh" ]]; then
	bash /data/config/profile.sh >/tmp/x.json
	jq --join-output --monochrome-output '{"shared_folders":. ,"worker_threads_count":1,"use_upnp":false}' /tmp/x.json >/tmp/c.json

	jq --join-output --monochrome-output --slurp '.[0] * .[1] * .[2]' /tmp/a.json /tmp/b.json /tmp/c.json >/tmp/config-static.json

	echo "starting settings update..."
	rslsync --nodaemon --config /tmp/config-static.json &
	sleep 10

	bash /opt/stop.sh
fi

echo "starting..."
cd /tmp
set -x
exec rslsync --nodaemon --config "/tmp/config-ui.json"
