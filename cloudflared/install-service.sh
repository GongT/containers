#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_flag PROXY proxy "use a socks5 proxy to connect remote"
arg_finish "$@"

create_pod_service_unit cloudflared@
unit_podman_image gongt/cloudflared '%i'
unit_unit Description "cloudflared - Argo Tunnel"
network_use_nat 40983
systemd_slice_type normal
environment_variable "PROXY=$PROXY"
unit_start_notify sleep "5"
unit_body RestartPreventExitStatus 233
unit_fs_bind data/cloudflared /root/.cloudflared
unit_fs_bind logs/cloudflared /var/log/cloudflared
shared_sockets_use

# healthcheck "30s" "5" "curl --insecure https://127.0.0.1:443"

unit_finish
