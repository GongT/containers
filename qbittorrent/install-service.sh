#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

create_pod_service_unit gongt/qbittorrent
unit_unit Description qbittorrent
unit_data danger
network_use_manual --network=bridge0 --mac-address=4A:E1:A2:4E:D5:6E
# unit_podman_arguments "$ENV_PASS"
# unit_body Restart always
unit_using_systemd
unit_podman_arguments --env="LANG=zh_CN.utf8"
unit_fs_bind config/qbittorrent /opt/qBittorrent/config
unit_fs_bind data/qbittorrent /opt/qBittorrent/data
unit_fs_bind /data/Volumes /data/Volumes
unit_fs_bind share/nginx /run/nginx
unit_fs_bind share/sockets /run/sockets
unit_finish
