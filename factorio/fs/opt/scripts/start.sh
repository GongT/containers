#!/bin/sh

set -Eeuo pipefail

declare -r GAME_INST=/opt/factorio
declare -r MAPFILE=/opt/data/map.zip

if ! [[ -e "$MAPFILE" ]]; then
	echo "map file ($MAPFILE) did not exists."
	exit 66
fi

sed -i "s/LOGIN_USERNAME_HERE/$USERNAME/g; s/LOGIN_PASSWORD_HERE/$PASSWORD/g" /opt/server-settings.json
if [[ "$GAME_PASSWORD" ]]; then
	sed -i "s/GAME_PASSWORD_HERE/$GAME_PASSWORD/g" /opt/server-settings.json
else
	sed -i "/GAME_PASSWORD_HERE/d" /opt/server-settings.json
fi

exec $GAME_INST/bin/x64/factorio \
	--port 34197 \
	--mod-directory "/opt/data/mods" \
	--server-settings "/opt/server-settings.json" \
	--console-log /dev/null \
	--server-id "/opt/data/server-id.json" \
	--start-server "$MAPFILE"
