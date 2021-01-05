#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + USERNAME u "RPC username"
arg_string + PASSWORD p "RPC password"
arg_finish "$@"

ENV_PASS=$(
	safe_environment \
		"USERNAME=$USERNAME" \
		"PASSWORD=$PASSWORD"
)

create_pod_service_unit gongt/bitcoin-peer
unit_unit Description bitcoin full peer service
# unit_start_notify output ""
network_use_auto 8333
unit_body Restart no
# unit_podman_image_pull never
unit_fs_bind share/nginx /run/nginx
shared_sockets_provide bittorrent-tracker

add_capability SYS_ADMIN
unit_podman_arguments "$ENV_PASS" --device=/dev/mapper/bitcoin-blockchain:/dev/xvda1:rw

unit_finish
