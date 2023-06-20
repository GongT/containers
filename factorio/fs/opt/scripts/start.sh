#!/usr/bin/bash

set -Eeuo pipefail

declare -r GAME_ROOT=/opt/factorio
if ! [[ "${DIST_TAG-}" ]]; then
	declare -xr DIST_TAG="stable"
fi
declare -r GAME_INST="$GAME_ROOT/$DIST_TAG"
declare -r SAVE_FILE="/data/map.zip"
declare -r GAME_BIN="$GAME_INST/bin/x64/factorio"

if ! [[ -e $SAVE_FILE ]]; then
	echo "map file ($SAVE_FILE) did not exists."
	exit 66
fi

cp -vfr "/opt/factorio/skel/." "$GAME_INST"

TITLE_VERSION=$("$GAME_BIN" --version | head -n1 | sed 's/^Version: //g' | sed -E 's/,.+$//g' | sed 's/(//g')

sed -i "s/GATE_SERVER_TITLE/$SERVER_TITLE [$DIST_TAG $TITLE_VERSION]/g; s/GAME_SERVER_DESCRIPTION/$SERVER_DESCRIPTION/g" /opt/server-settings.json
sed -i "s/LOGIN_USERNAME_HERE/$USERNAME/g; s/LOGIN_PASSWORD_HERE/$PASSWORD/g" /opt/server-settings.json
if [[ "$GAME_PASSWORD" ]]; then
	sed -i "s/GAME_PASSWORD_HERE/$GAME_PASSWORD/g" /opt/server-settings.json
else
	sed -i "/GAME_PASSWORD_HERE/d" /opt/server-settings.json
fi

sed -i "s/RCON_PORT/$RCON_PORT/g" "$GAME_INST/config/config.ini"

if [[ ! $PROXY_SERVER ]]; then
	PROXY_SERVER=
fi
sed -i "s/PROXY_SERVER/$PROXY_SERVER/g" "$GAME_INST/config/config.ini"

{
	if [[ "${RESOLVE_OPTIONS-}" ]]; then
		echo "options $RESOLVE_OPTIONS"
	fi
	if [[ "${RESOLVE_SEARCH-}" ]]; then
		echo "options $RESOLVE_SEARCH"
	fi
	if [[ "${NSS-}" ]]; then
		mapfile -d ' ' -t NSS < <(echo "$NSS")
		for NS in "${NSS[@]}"; do
			echo "nameserver $NS"
		done
	else
		echo "nameserver 8.8.8.8"
	fi
} >/etc/resolv.conf

exec "$GAME_BIN" \
	--port "$SERVER_PORT" \
	--mod-directory "/data/mods" \
	--server-settings "/opt/server-settings.json" \
	--console-log /dev/null \
	--server-id "/data/server-id.json" \
	--start-server "$SAVE_FILE"
