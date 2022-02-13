#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

create_pod_service_unit gongt/resiliosync
unit_unit Description ResilioSync service
unit_data danger

network_use_auto 35515
systemd_slice_type idle -100

unit_start_notify output 'Features mask has been set to'
# unit_podman_arguments "$ENV_PASS"
# unit_body Restart always
unit_fs_bind config/resiliosync /data/config
unit_fs_bind data/resiliosync /data/state
unit_fs_bind /data/Volumes /data/Volumes
unit_fs_bind share/nginx /run/nginx

unit_podman_arguments --env="LANG=zh_CN.utf8"
shared_sockets_provide resiliosync

unit_finish
