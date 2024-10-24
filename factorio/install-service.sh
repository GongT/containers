#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

PORT=34197
DIST_TAG=stable

arg_string + SERVER_TITLE title "server title"
arg_string - SERVER_DESCRIPTION desc "server description"
arg_string + LOGIN login "factorio login user:pass (or token)"
arg_string - GAME_PASSWORD password "server join password"
arg_string - DIST_TAG dist-tag "version (stable or latest)"
arg_string - PORT port "server port"
arg_finish "$@"

declare -i RCON_PORT="$PORT - 34197 + 27015"

LOGIN_USER=${LOGIN%%:*}
LOGIN_PASS=${LOGIN#*:}

auto_create_pod_service_unit
unit_podman_image registry.gongt.me/gongt/factorio
unit_unit Description factorio server

# unit_podman_image_pull never
unit_data danger
unit_body TimeoutStartSec 300s
# unit_start_notify output "Obtained serverPadlock for serverHash"

network_use_pod gateway "$PORT/udp" "$RCON_PORT/tcp"
systemd_slice_type entertainment

unit_fs_bind "/data/Volumes/GameDisk/GameSave/factorio" /data
unit_fs_tempfs 512M /data/temp

unit_podman_safe_environment \
	"SERVER_TITLE=${SERVER_TITLE}" \
	"SERVER_DESCRIPTION=${SERVER_DESCRIPTION}" \
	"LOGIN_USER=${LOGIN_USER}" \
	"LOGIN_PASS=${LOGIN_PASS}" \
	"GAME_PASSWORD=${GAME_PASSWORD:-}" \
	"DIST_TAG=${DIST_TAG}" \
	"SERVER_PORT=${PORT}" \
	"RCON_PORT=${RCON_PORT}" \
	"PROXY_SERVER=http://proxy-server.internal:3271"

unit_finish
