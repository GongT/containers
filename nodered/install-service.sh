#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish "$@"

create_pod_service_unit nodered/node-red
unit_unit Description Low-code programming for event-driven applications
network_use_auto 1880/tcp 8883/tcp
# unit_start_notify output "start worker process"
# unit_fs_bind /etc/localtime /etc/localtime ro
unit_fs_bind config/nodered /config
unit_fs_bind data/nodered /data
unit_fs_bind share/nginx /run/nginx
shared_sockets_use

unit_finish
