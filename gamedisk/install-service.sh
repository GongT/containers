#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

auto_create_pod_service_unit
unit_podman_image gongt/gamedisk
# unit_podman_image_pull never
unit_unit Description "iSCSI target daemon for game disk"
unit_data danger

unit_podman_arguments "--env=DISK_TO_USE=/dev/mapper/scsi-game"
use_full_system_privilege
unit_fs_bind /dev/mapper /dev/mapper
unit_fs_bind gamedisk-leases /var/lib/dhclient
unit_start_notify output "tgtd configured"

systemd_slice_type infrastructure

network_use_manual --network=bridge0 --mac-address=3E:F4:F3:CE:1D:80
unit_finish
