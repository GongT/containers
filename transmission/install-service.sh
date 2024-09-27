#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish

create_it() {
	create_pod_service_unit "transmission-$INSTANCE_NAME"
	unit_podman_image registry.gongt.me/gongt/transmission
	# unit_podman_image_pull never
	unit_unit Description transmission

	unit_data danger

	unit_using_systemd
	add_network_privilege
	
	network_use_manual --network=bridge0 "--mac-address=$MAC_ADDRESS"
	systemd_slice_type idle

	environment_variable "INSTANCE_NAME=$INSTANCE_NAME"
	# unit_body ExecStop '/usr/bin/podman exec $CONTAINER_ID /usr/bin/bash /opt/scripts/stop.sh'

	# podman_engine_params --env="LANG=zh_CN.utf8"
	shared_sockets_provide "transmission.$INSTANCE_NAME"

	unit_unit After network-online.target
	# unit_body Restart always
	unit_start_notify output "SYSTEM_STARTUP_COMPLETE"

	unit_fs_bind "data/transmission.$INSTANCE_NAME" /opt/data
	unit_fs_bind config/transmission /opt/config
	unit_fs_bind "$TARGET" /data

	unit_finish
}

MAC_ADDRESS=f0:dd:7a:90:46:b6
INSTANCE_NAME=software
TARGET=/data/Volumes/UserData
create_it
