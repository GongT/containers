#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish "$@"

create_pod_service_unit homeassistant
unit_podman_image registry.gongt.me/gongt/homeassistant
unit_unit Description Open source home automation that puts local control and privacy first.
network_use_manual --network=br-lan --mac-address=4C:3A:8E:97:25:53 --dns=10.0.0.1
unit_podman_image_pull never
use_full_system_privilege
use_proxy_server
unit_start_notify output "service legacy-services successfully started"
# unit_fs_bind /etc/localtime /etc/localtime ro
unit_fs_bind config/homeassistant /config
unit_fs_bind share/nginx /run/nginx
unit_volume homeassistant /run/nginx
shared_sockets_use

unit_podman_safe_environment "LANG=${LANG:-zh_CN.UTF-8}"

unit_finish
