#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish "$@"

create_pod_service_unit gongt/liverecord
unit_depend nginx.pod.service

unit_podman_image registry.gongt.me/gongt/liverecord

systemd_slice_type entertainment
# environment_variable "LIVE_ROOMS=$LIVE_ROOMS" "${PROXY[@]}" "BREC_HTTP_OPEN_ACCESS=yes"

shared_sockets_provide liverecord

unit_fs_bind "/data/Volumes/VideoRecord/bilibili" /data/records
unit_fs_bind config/liverecord /opt/app/bin/Config/

unit_finish
