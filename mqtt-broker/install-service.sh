#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + USERNAME u/user "mqtt connect username"
arg_string + PASSWORD p/password "mqtt connect password"
arg_finish "$@"

create_pod_service_unit gongt/mqtt-broker
unit_unit After nginx.pod.service
unit_start_notify output 'mosquitto version'
network_use_nat
systemd_slice_type normal
# unit_body Restart no
# unit_podman_image_pull never
unit_body ExecStop '/usr/bin/podman exec $CONTAINER_ID bash /opt/stop.sh'
unit_fs_bind data/mqtt /data
unit_fs_bind config/mqtt /settings

shared_sockets_provide mqtt

unit_podman_safe_environment \
	"USERNAME=$USERNAME" \
	"PASSWORD=$PASSWORD"

unit_finish
