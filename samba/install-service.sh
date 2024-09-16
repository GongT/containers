#!/usr/bin/env bash

set -e

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + DEFAULT_PASSWORD p/password "default user (media_rw) password"
arg_string + HOSTNAME h/hostname "samba hostname"
arg_finish "$@"

auto_create_pod_service_unit
unit_podman_image gongt/samba

unit_podman_hostname "$HOSTNAME"
unit_unit Description "standalone samba server"

add_network_privilege
network_use_veth bridge0
podman_engine_params --mac-address=3E:F4:F3:CE:1D:75

unit_body Restart no
unit_data danger
systemd_slice_type infrastructure

environment_variable "DEFAULT_PASSWORD=$DEFAULT_PASSWORD"

unit_fs_bind /data/Volumes /drives
unit_fs_bind /data/DevelopmentRoot /mountpoints/DevelopmentRoot
unit_fs_bind config/samba /opt/config
unit_fs_bind logs/samba /var/log/samba
# unit_fs_tempfs 1G /var/run

MOUNTS=(/data/DevelopmentRoot)
for I in /data/Volumes/*/; do
	MOUNTS+=("$(realpath "$I")")
done
unit_unit RequiresMountsFor "${MOUNTS[*]}"

unit_finish
