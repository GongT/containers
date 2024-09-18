#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish "$@"

create_pod_service_unit gongt/ethereum-peer
unit_unit Description ethereum full peer service
# unit_start_notify output ""
network_use_auto 30303
systemd_slice_type idle
# unit_body Restart no
unit_body TimeoutStopSec 1min

shared_sockets_provide ethereum-tracker

add_capability SYS_ADMIN
unit_podman_arguments --device=/dev/mapper/cryptocurrency-ethereum:/dev/xvda1:rw

unit_finish
