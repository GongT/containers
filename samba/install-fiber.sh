#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=./tool.sh
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/tool.sh"

### 10G net
create_pod_service_unit fiber-samba
unit_podman_hostname samba.fiberhost
unit_unit Description "samba server in fiber host"
systemd_slice_type normal

network_use_container fiberhost

commonConfig
unit_finish
