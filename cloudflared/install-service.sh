#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_flag PROXY proxy "use a socks5 proxy to connect remote"
arg_finish "$@"

ENV_PASS=$(
	safe_environment \
		"PROXY=$PROXY"
)

create_pod_service_unit cloudflared@
unit_podman_image gongt/cloudflared '%i'
unit_unit Description "cloudflared - Argo Tunnel"
network_use_bridge
unit_podman_arguments "$ENV_PASS"
unit_start_notify sleep "5"
unit_body RestartPreventExitStatus 233
unit_fs_bind data/cloudflared /root/.cloudflared
unit_fs_bind logs/cloudflared /var/log/cloudflared
shared_sockets_use

# healthcheck "30s" "5" "curl --insecure https://127.0.0.1:443"

unit_finish
