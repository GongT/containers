#!/usr/bin/bash

set -Eeuo pipefail

if ! [[ "${DIST_TAG-}" ]] || ! [[ "${GAME_INST-}" ]]; then
	echo "Missing DIST_TAG or GAME_INST"
	exit 233
fi

declare -r SAVE_FILE="/data/map/map.zip"
if ! [[ -e $SAVE_FILE ]]; then
	echo "map file ($SAVE_FILE) did not exists."
	exit 233
fi

######## Update server config json
TITLE_VERSION=$("${GAME_INST}/bin/x64/factorio" --version | head -n1 | sed 's/^Version: //g' | sed -E 's/,.+$//g' | sed 's/(//g')

sed -i "s/GATE_SERVER_TITLE/$SERVER_TITLE [$DIST_TAG $TITLE_VERSION]/g; s/GAME_SERVER_DESCRIPTION/$SERVER_DESCRIPTION/g" /opt/server-settings.json
sed -i "s/LOGIN_USERNAME_HERE/$LOGIN_USER/g" /opt/server-settings.json
if [[ ${#LOGIN_PASS} -eq 30 ]]; then
	sed -i "/LOGIN_PASSWORD_HERE/d" /opt/server-settings.json
	sed -i "s/LOGIN_TOKEN_HERE/$LOGIN_PASS/g" /opt/server-settings.json
else
	sed -i "s/LOGIN_PASSWORD_HERE/$LOGIN_PASS/g" /opt/server-settings.json
	sed -i "/LOGIN_TOKEN_HERE/d" /opt/server-settings.json
fi

if [[ "$GAME_PASSWORD" ]]; then
	sed -i "s/GAME_PASSWORD_HERE/$GAME_PASSWORD/g" /opt/server-settings.json
else
	sed -i "/GAME_PASSWORD_HERE/d" /opt/server-settings.json
fi

######## Update gameplay config ini
declare -r SETTINGS_FILE='/data/config/config.ini'
function replace_config() {
	local -r NAME="$1" VALUE="$2"
	local -r MATCH="^(;\s*)?${NAME}=.*$" REPLACE="${NAME}=${VALUE}"

	if grep -F "${REPLACE}" "${SETTINGS_FILE}"; then
		return 0
	fi

	if ! grep -E "${MATCH}" "${SETTINGS_FILE}"; then
		echo "missing setting field: ${NAME}"
		exit 1
	fi
	echo "override config value ${REPLACE}"
	sed -i -E "s#${MATCH}#${REPLACE}#" "${SETTINGS_FILE}"
}

replace_config "read-data" "__PATH__executable__/../../data"
replace_config "write-data" "/data"
replace_config "local-rcon-socket" "0.0.0.0:${RCON_PORT}"
if [[ ${PROXY_SERVER-} ]]; then
	replace_config "proxy" "${PROXY_SERVER}"
fi
replace_config "local-rcon-password" "123456"

########## START

set -x
exec "${GAME_INST}/bin/x64/factorio" \
	--port "${SERVER_PORT}" \
	--mod-directory "/data/mods" \
	--server-settings "/opt/server-settings.json" \
	--console-log /dev/null \
	--server-id "/data/config/server-id.json" \
	--start-server "${SAVE_FILE}"
