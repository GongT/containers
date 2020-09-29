#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + USERNAME u "factorio online game username"
arg_string + PASSWORD p "factorio online game password"
arg_string   GAME_PASSWORD password "server join password"
arg_finish "$@"

ENV_PASS=$(
	safe_environment \
		"USERNAME=$USERNAME" \
		"PASSWORD=$PASSWORD" \
		"GAME_PASSWORD=$GAME_PASSWORD"
)

create_pod_service_unit gongt/factorio
unit_unit Description factorio server
unit_data danger
unit_body TimeoutStartSec 60s
unit_body RestartPreventExitStatus 66
unit_start_notify output "Obtained serverPadlock for serverHash"
unit_podman_arguments "$ENV_PASS"
network_use_auto 34197 # --mac-address=9E:49:F9:6B:6B:82 --network=bridge0
unit_fs_bind data/factorio /data
unit_fs_tempfs 512M /data/temp
unit_finish
