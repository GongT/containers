#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

create_pod_service_unit gongt/qbittorrent
unit_unit Description qbittorrent
for I in /data/Volumes/*; do
	unit_unit RequiresMountsFor "${I}"
done

network_use_veth bridge0
podman_engine_params --mac-address=4A:E1:A2:4E:D5:6E
add_network_privilege

unit_data danger
systemd_slice_type idle
# unit_body Restart always

unit_fs_bind config/qbittorrent /opt/qBittorrent/config
unit_fs_bind data/qbittorrent /opt/qBittorrent/data
unit_fs_bind data/qbittorrent/HOME /home/media_rw
unit_fs_bind /data/Volumes /data/Volumes

unit_body TimeoutStartSec 2min
podman_engine_params --env="LANG=zh_CN.utf8"
shared_sockets_provide qbittorrent-admin

unit_finish
