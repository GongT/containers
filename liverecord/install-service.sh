#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + LIVE_ROOM r/room "直播间ID"
arg_finish "$@"

create_pod_service_unit gongt/liverecord@
unit_podman_arguments "--env=WATCH_LIVEROOM=%i"
# unit_start_notify output 'mosquitto version'
network_use_nat
systemd_slice_type normal

unit_body Restart no
# unit_podman_image_pull never
unit_fs_bind "/data/Volumes/VideoRecord/bilibili/%i/raw" /data/raw
unit_fs_bind "/data/Volumes/VideoRecord/bilibili/%i/mp4" /data/mp4
unit_finish

systemctl enable "liverecord.pod@$LIVE_ROOM.service"
