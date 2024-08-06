#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

create_pod_service_unit gongt/bttracker
unit_unit Description bttracker
# unit_body Restart always
# unit_podman_image_pull never

unit_start_notify output "::load:complete::"
network_use_auto 6969/udp 6969/tcp
systemd_slice_type idle

unit_finish
