#!/usr/bin/env bash

set -Eeuo pipefail

mapfile -t -d ',' ARR_ROOMS < <(echo -n "$LIVE_ROOMS")

if ! [[ -e /data/config.json.original ]]; then
	cp /data/config.json /data/config.json.original
fi

function _jq() {
	echo -e "\e[2mjq -Mcr $*\e[0m" >&2
	jq -Mcr "$@"
}

ROOM_TEMPLATE=$(_jq '.rooms[0]' /data/config.json.original)
FILE_DATA=$(_jq '.rooms = []' /data/config.json.original)

for ROOM in "${ARR_ROOMS[@]}"; do
	SECTION=$(echo "$ROOM_TEMPLATE" | _jq --argjson room "$ROOM" '.RoomId.Value = $room')
	FILE_DATA=$(echo "$FILE_DATA" | _jq --argjson section "$SECTION" '.rooms += [$section]')
done

echo "$FILE_DATA" >/data/config.json
