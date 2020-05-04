#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

create_pod_service_unit memcached
unit_podman_image memcached:alpine memcached -u root -m 2048 -c 4096 -t 8 -v -L -s /run/sockets/memcached.sock -a 0777
unit_podman_image_pull missing
unit_podman_arguments --user=root
unit_fs_bind share/sockets /run/sockets
unit_finish
