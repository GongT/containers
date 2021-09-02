#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

create_pod_service_unit gongt/bttracker
unit_unit Description bttracker
unit_start_notify output "Ok, All setup"
# network_use_auto 43079/udp
systemd_slice_type idle
# unit_body Restart always
# unit_podman_image_pull never
unit_fs_bind share/nginx /run/nginx
unit_fs_bind data/bttracker /data/store
shared_sockets_provide bittorrent-tracker
unit_finish
