#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + DEFAULT_PASSWORD p/password "default user (media_rw) password"
arg_string + HOSTNAME h/hostname "samba hostname"
arg_finish "$@"

mkdir -p "$CONTAINERS_DATA_PATH/config/samba"
echo "DEFAULT_PASSWORD=$DEFAULT_PASSWORD" | write_file "$CONTAINERS_DATA_PATH/config/samba/environments"

function commonConfig() {
	# unit_body Restart always
	unit_data danger

	unit_using_systemd

	unit_start_notify output "smb service startup complete"

	unit_body TimeoutStartSec 5min
	unit_podman_image gongt/samba
	unit_podman_arguments --env="DEFAULT_PASSWORD=$DEFAULT_PASSWORD"

	unit_fs_bind /data/Volumes /drives
	unit_fs_bind /dev/shm /mountpoints/shm
	unit_fs_bind /data/DevelopmentRoot /mountpoints/DevelopmentRoot
	unit_fs_bind config/samba /opt/config
	unit_fs_bind logs/samba /var/log/samba
	unit_fs_tempfs 1G /var/run

	unit_unit RequiresMountsFor \
		/data/Volumes/H \
		/data/Volumes/Anime \
		/data/Volumes/BigCache \
		/data/Volumes/GameDisk \
		/data/Volumes/UserData \
		/data/Volumes/VideoRecord

	add_network_privilege
	add_capability SYS_ADMIN
	# use_full_system_privilege # TODO
}
