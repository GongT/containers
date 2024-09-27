#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

auto_create_pod_service_unit
unit_podman_image registry.gongt.me/gongt/gamedisk
unit_unit Description "iSCSI target daemon for game disk"

unit_unit After 'dev-mapper-game\x2dscsi.device'
unit_unit Requires 'dev-mapper-game\x2dscsi.device'
environment_variable "DISK_TO_USE=/dev/xvdb"
podman_engine_params --device=/dev/mapper/game-scsi:/dev/xvdb:rw

# unit_podman_image_pull never
unit_data danger
systemd_slice_type infrastructure

add_network_privilege
network_use_veth bridge0
podman_engine_params --mac-address=3E:F4:F3:CE:1D:80

unit_finish
