#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish

auto_create_pod_service_unit
unit_podman_image gongt/qqbot
unit_unit Description QQ bot

systemd_slice_type normal

add_network_privilege
network_use_veth bridge0
podman_engine_params --mac-address=3E:F4:F3:CE:1D:42
shared_sockets_provide qqbot.novnc qqbot.vnc

unit_fs_bind data/qqbot/bots /opt/loader_data
unit_fs_bind data/qqbot/qqnt /home/qq/.config/QQ

unit_finish
