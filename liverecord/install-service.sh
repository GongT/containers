#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + LIVE_ROOMS r/rooms "直播间ID（多个用逗号分开）"
arg_finish "$@"

create_pod_service_unit gongt/liverecord
unit_start_notify output '弹幕服务器已连接'

PROXY=()
for I in http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY; do
	PROXY+=("$I=http://proxy-server.:3271")
done

systemd_slice_type normal
environment_variable "LIVE_ROOMS=$LIVE_ROOMS" "${PROXY[@]}" "BREC_HTTP_OPEN_ACCESS=yes"
unit_podman_arguments '--dns-env=p.a.s.s'

unit_body Restart on-failure
unit_body TimeoutStartSec 2min
# unit_podman_image_pull never

network_use_bridge
unit_fs_bind share/nginx /run/nginx
shared_sockets_provide liverecord

unit_fs_bind "/data/Volumes/VideoRecord/bilibili" /data/records
unit_fs_bind logs/liverecord /app/logs

unit_finish
