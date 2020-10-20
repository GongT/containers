#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + DEFAULT_PASSWORD p/password "default user (media_rw) password"
arg_string + HOSTNAME h/hostname "samba hostname"
arg_finish

function commonConfig() {
	# unit_body Restart always
	unit_data danger

	unit_using_systemd
	add_capability SYS_ADMIN

	unit_start_notify output "daemon_ready: daemon 'smbd' finished starting up"

	unit_podman_image gongt/samba
	unit_podman_arguments --env="DEFAULT_PASSWORD=$DEFAULT_PASSWORD"

	unit_fs_bind /data/Volumes /drives
	unit_fs_bind /dev/shm /mountpoints/shm
	unit_fs_bind /data/DevelopmentRoot /mountpoints/DevelopmentRoot
	unit_fs_bind config/samba /opt/config
	unit_fs_bind logs/samba /var/log/samba

	unit_reload_command '/usr/bin/podman exec $CONTAINER_ID /usr/bin/reload-samba'

	add_network_privilege
}

mkdir -p "$CONTAINERS_DATA_PATH/config/samba"
echo "DEFAULT_PASSWORD=$DEFAULT_PASSWORD" | write_file "$CONTAINERS_DATA_PATH/config/samba/environments"

### 10G net
create_pod_service_unit fiber-samba
unit_podman_hostname samba.fiberhost
unit_unit Description "samba server in fiber host"

network_use_container fiberhost

commonConfig
unit_finish

### 1000M net
create_pod_service_unit samba
unit_podman_hostname $HOSTNAME
unit_unit Description "standalone samba server"

network_use_manual --network=bridge0 --mac-address=3E:F4:F3:CE:1D:75 --dns=none
unit_podman_arguments --env=ENABLE_DHCP=yes

commonConfig
unit_finish
