#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish

create_pod_service_unit "teamspeak"
unit_podman_image registry.gongt.me/gongt/teamspeak
# unit_podman_image_pull never
unit_unit Description TeamSpeak

network_use_default 9987/udp 30033/tcp 10022/tcp 10080/tcp
systemd_slice_type entertainment

# podman_engine_params --env="LANG=zh_CN.utf8"

unit_unit After network-online.target

unit_fs_bind data/teamspeak /data
unit_fs_bind config/teamspeak /etc/teamspeak
unit_fs_bind logs/teamspeak /var/log/teamspeak
shared_sockets_use

unit_finish
