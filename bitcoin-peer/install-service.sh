#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + USERNAME u "RPC username"
arg_string + PASSWORD p "RPC password"
arg_finish "$@"

create_pod_service_unit gongt/bitcoin-peer
unit_unit Description bitcoin full peer service
unit_start_notify output "Verifying blocks"
network_use_auto 8333
systemd_slice_type idle
# unit_body Restart no
unit_body TimeoutStopSec 1min
# unit_podman_image_pull never

shared_sockets_provide bittorrent-tracker

add_capability SYS_ADMIN

environment_variable \
	"USERNAME=$USERNAME" \
	"PASSWORD=$PASSWORD"
unit_podman_arguments --device=/dev/mapper/cryptocurrency-bitcoin:/dev/xvda1:rw

unit_finish
