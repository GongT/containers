#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

create_pod_service_unit gongt/bitcoind
unit_unit Description bitcoin full peer service
# unit_start_notify output ""
network_use_auto 8333
# unit_body Restart never
# unit_podman_image_pull never
unit_fs_bind share/nginx /run/nginx
shared_sockets_provide bittorrent-tracker

add_capability SYS_ADMIN
unit_podman_arguments --device=/dev/mapper/bitcoin-blockchain:/dev/xvda1:rw

unit_finish
