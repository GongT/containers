#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

auto_create_pod_service_unit
unit_podman_image gongt/impostor
unit_unit Description "impostor among us server"
unit_data danger

unit_fs_bind data/impostor /data
unit_start_notify output "Application started."

# unit_body Restart always
network_use_auto 22023/udp 22024/udp 22025/udp
systemd_slice_type entertainment

unit_finish
