#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish "$@"

create_pod_service_unit auto-bangumi
unit_podman_image registry.gongt.me/gongt/auto-bangumi
unit_unit Description "AutoBangumi 是基于 RSS 的全自动追番整理下载工具"

unit_data danger
systemd_slice_type idle

add_network_privilege
network_use_veth bridge0
podman_engine_params --mac-address=91:11:5D:E7:FB:2B

unit_fs_bind /data/Volumes/Anime/AutoBangumi /app/data
unit_fs_bind config/auto-bangumi /app/config
unit_fs_bind config/auto-bangumi /opt/qBittorrent/config
unit_fs_bind data/auto-bangumi /opt/qBittorrent/data
unit_fs_bind data/auto-bangumi/HOME /home/media_rw

unit_body TimeoutStartSec 2min
shared_sockets_provide auto-bangumi auto-bangumi-qbittorrent

unit_unit RequiresMountsFor /data/Volumes/Anime

unit_finish
