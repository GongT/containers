#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish "$@"

create_pod_service_unit gitrepo
unit_podman_image registry.gongt.me/gongt/gitrepo
unit_unit Description simple git repos
unit_unit After gateway-network.pod.service

network_use_void
systemd_slice_type idle

unit_fs_bind data/gitrepos /repos
shared_sockets_provide gitrepo
unit_body RestartSec 30s

unit_finish
