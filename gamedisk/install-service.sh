#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

auto_create_pod_service_unit
unit_podman_image gongt/gamedisk
# unit_podman_image_pull never
unit_unit Description "iSCSI target daemon for game disk"
unit_data danger

unit_unit After 'dev-mapper-game\x2dscsi.device'
unit_unit Requires 'dev-mapper-game\x2dscsi.device'
environment_variable "DISK_TO_USE=/dev/mapper/game-scsi"

unit_fs_bind /dev/mapper /dev/mapper
unit_start_notify output "TGTD-COMPLETE-START"

systemd_slice_type infrastructure
unit_using_systemd
# add_capability SYS_ADMIN
add_network_privilege
use_full_system_privilege

network_use_manual --network=bridge0 --mac-address=3E:F4:F3:CE:1D:80
unit_finish

