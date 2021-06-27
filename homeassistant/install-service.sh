#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish "$@"

ENV_PASS=$(
	safe_environment \
		"LANG=${LANG:-zh_CN.UTF-8}" \
)


create_pod_service_unit homeassistant
unit_podman_image homeassistant/home-assistant:stable
unit_unit Description Open source home automation that puts local control and privacy first.
network_use_auto 8123/tcp 8883/tcp
# unit_podman_arguments "$ENV_PASS"
# unit_start_notify output "start worker process"
# unit_fs_bind /etc/localtime /etc/localtime ro
unit_fs_bind config/homeassistant /config
unit_fs_bind share/nginx /run/nginx
shared_sockets_use

unit_finish
