#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish "$@"

create_pod_service_unit gongt/dd-at-home
unit_podman_image gongt/ddathome
network_use_auto
systemd_slice_type idle

unit_body Restart on-failure
unit_podman_image_pull never
unit_finish
