#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

auto_create_pod_service_unit
unit_podman_image gongt/gamedisk
unit_unit Description "iSCSI target daemon for game disk"
unit_data danger

unit_podman_arguments "--env=DISK_TO_USE=/dev/mapper/scsi-game"
use_full_system_privilege
unit_fs_bind /dev/mapper /dev/mapper
unit_start_notify output "tgtd configured"

# unit_body Restart always
network_use_container fiberhost
unit_finish
