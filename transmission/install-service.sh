#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

create_pod_service_unit gongt/transmission
unit_unit Description transmission
unit_data danger

network_use_auto 43070
systemd_slice_type idle -101

# unit_start_notify output "State changed from 'Starting' to"
unit_fs_bind data/transmission /opt/data
unit_fs_bind config/transmission /opt/config
unit_fs_bind /data/Volumes /data/Volumes
unit_fs_bind share/nginx /run/nginx

unit_reload_command '/usr/bin/podman exec $CONTAINER_ID /usr/bin/bash /opt/scripts/reload.sh'
unit_body ExecStop '/usr/bin/podman exec $CONTAINER_ID /usr/bin/bash /opt/scripts/stop.sh'

unit_podman_arguments --env="LANG=zh_CN.utf8"
shared_sockets_provide transmission-admin

unit_finish
