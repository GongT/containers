#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

create_pod_service_unit gongt/bttracker
unit_unit Description bttracker
# unit_body Restart always
# unit_podman_image_pull never

unit_start_notify sleep 5
network_use_auto 43079/udp 43079/tcp
systemd_slice_type idle

unit_finish
