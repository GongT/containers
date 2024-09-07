#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + CF_TOKEN token "cloudflare api token"
arg_string + CF_ZONE_ID zone "cloudflare dns zone"
arg_string + CF_RECORD_ID4 4 "record id"
arg_string + CF_RECORD_ID6 6 "record id"
arg_string + HOST_NAME h/host "full domain name"
arg_finish "$@"

auto_create_pod_service_unit
unit_podman_image gongt/virtual-gateway
unit_unit Description virtual machine gateway
# unit_podman_image_pull never

unit_unit After network-online.target

# unit_body Restart always
unit_start_notify output "SYSTEM_STARTUP_COMPLETE"

network_use_manual --network=bridge0 --mac-address=86:13:02:8F:76:2A --dns-env=p.a.s.s --dns-env=ns1.he.net
systemd_slice_type infrastructure

unit_using_systemd
add_network_privilege
use_full_system_privilege

unit_podman_safe_environment \
	"CF_TOKEN=${CF_TOKEN}" \
	"CF_ZONE_ID=${CF_ZONE_ID}" \
	"CF_RECORD_ID4=${CF_RECORD_ID4}" \
	"CF_RECORD_ID6=${CF_RECORD_ID6}" \
	"HOST_NAME=${HOST_NAME}"
unit_fs_bind data/virtual-gateway /storage

unit_finish

# mkdir -p "/etc/systemd/system/cockpit.socket.d"
# echo "[Socket]
# ListenStream=$SHARED_SOCKET_PATH/cockpit.sock
# ExecStartPost=
# ExecStopPost=
# " >"/etc/systemd/system/cockpit.socket.d/listen-socket.conf"

# systemctl daemon-reload
