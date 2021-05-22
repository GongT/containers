#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish "$@"

create_pod_service_unit ethereum-peer
unit_podman_image ethereum/client-go:stable
unit_unit Description ethereum full peer service
# unit_start_notify output ""
network_use_auto 30303
# unit_body Restart no
unit_body TimeoutStopSec 1min
# unit_podman_image_pull never
unit_fs_bind share/nginx /run/nginx
shared_sockets_provide ethereum-tracker

add_capability SYS_ADMIN
unit_podman_arguments "$ENV_PASS" --device=/dev/mapper/cryptocurrency-ethereum:/dev/xvda1:rw

unit_finish
