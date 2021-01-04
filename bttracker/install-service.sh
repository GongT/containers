#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

create_pod_service_unit gongt/bttracker
unit_unit Description bttracker
unit_start_notify output "Ok, All setup"
network_use_auto
# unit_body Restart always
# unit_podman_image_pull never
unit_fs_bind share/nginx /run/nginx
shared_sockets_provide bittorrent-tracker
unit_finish
