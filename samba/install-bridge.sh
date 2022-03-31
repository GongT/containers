#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=./tool.sh
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/tool.sh"

### use bridge
create_pod_service_unit samba
unit_unit Description "samba server with mapped port"
systemd_slice_type normal

network_use_nat 137/udp 138/udp 139/tcp 445/tcp

commonConfig
unit_finish
