#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit extglob nullglob globstar lastpipe shift_verbose

x() {
	echo "$*" >&2
	"$@"
}

ARGS=("")

if [[ -e "/data/config/license.key" ]]; then
	ARGS+=()
fi

hjson -j /opt/base-config.jsonc >/tmp/config.json

if [[ -e "/data/config/profile.sh" ]]; then
	echo "using profile!"
	PROFILE_JSON=$(bash /data/config/profile.sh | hjson -j)
	jq --join-output --monochrome-output '.shared_folders = $ARGS.named.folders' --argjson folders "${PROFILE_JSON}" /tmp/config.json >/tmp/config-static.json

	echo "starting settings update..."
	x /usr/bin/rslsync --nodaemon --config /tmp/config-static.json &

	sleep 10

	echo "ending settings update..."
	PID=$(</tmp/resilio.pid)
	kill -s SIGINT "${PID}"

	echo "wait shutdown"
	wait

	rm -f /tmp/config-static.json

	echo "complete!"
else
	echo "profile not exists"
fi

if [[ -e "/data/config/license.key" ]]; then
	echo "apply new license key"
	x /usr/bin/rslsync --nodaemon --config "/tmp/config.json" "--license" "/data/config/license.key"
	mv /data/config/license.key /data/config/license.key.current
else
	echo "no new license file, it can be at /data/config/license.key"
fi

rm -f /tmp/resilio.pid
chown media_rw:users /data/state -R
