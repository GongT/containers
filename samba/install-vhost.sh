#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=./tool.sh
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/tool.sh"

### 1000M net
create_pod_service_unit samba
unit_podman_hostname "$HOSTNAME"
unit_unit Description "standalone samba server"

network_use_manual --network=bridge0 --mac-address=3E:F4:F3:CE:1D:75
systemd_slice_type infrastructure
unit_podman_arguments --env=ENABLE_DHCP=yes

commonConfig
unit_finish
