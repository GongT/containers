#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

PORT=34197
DIST_TAG=stable

arg_string + SERVER_TITLE title "server title"
arg_string SERVER_DESCRIPTION desc "server description"
arg_string + USERNAME u "factorio user username"
arg_string + PASSWORD p "factorio user password"
arg_string GAME_PASSWORD password "server join password"
arg_string DIST_TAG dist-tag "version (stable or latest)"
arg_string PORT port "server port"
arg_finish "$@"

declare -i RCON_PORT="$PORT - 34197 + 27015"

create_pod_service_unit factorio
unit_podman_image registry.gongt.me/gongt/factorio
unit_unit Description factorio server
unit_data danger
unit_body TimeoutStartSec 300s
unit_body RestartPreventExitStatus 66
unit_start_notify output "Obtained serverPadlock for serverHash"

network_use_auto "$PORT/udp" "$RCON_PORT/tcp"
systemd_slice_type entertainment

unit_fs_bind "/data/Volumes/GameDisk/GameSave/factorio/save" /data
unit_fs_bind "/data/Volumes/GameDisk/GameSave/factorio/mods" /data/mods ro
unit_fs_bind "/data/Volumes/GameDisk/GameSave/factorio/backup" /data/saves
unit_fs_tempfs 512M /data/temp

unit_podman_safe_environment \
	"SERVER_TITLE=$SERVER_TITLE" \
	"SERVER_DESCRIPTION=$SERVER_DESCRIPTION" \
	"USERNAME=$USERNAME" \
	"PASSWORD=$PASSWORD" \
	"GAME_PASSWORD=${GAME_PASSWORD:-}" \
	"DIST_TAG=$DIST_TAG" \
	"SERVER_PORT=$PORT" \
	"RCON_PORT=$RCON_PORT" \
	"PROXY_SERVER=proxy-server.:3271"

unit_finish
