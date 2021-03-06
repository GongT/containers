#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + DDNS_HOST h/host "ddns host FQDN"
arg_string + DSNS_KEY k/key "ddns api key"
arg_string + PASSWORD p/password "wireguard config client password"
arg_finish "$@"

auto_create_pod_service_unit
unit_podman_image gongt/virtual-gateway
unit_unit Description virtual machine gateway
# unit_podman_image_pull never

unit_unit After network-online.target wait-mount.service

# unit_body Restart always
unit_start_notify output "network startup complete"

network_use_manual --network=bridge0 --mac-address=86:13:02:8F:76:2A --dns-env=p.a.s.s --dns-env=ns1.he.net
add_network_privilege

unit_podman_safe_environment \
	"DSNS_KEY=${DSNS_KEY}" \
	"DDNS_HOST=${DDNS_HOST}" \
	"WIREGUARD_PASSWORD=$PASSWORD"

unit_fs_bind data/virtual-gateway /storage

unit_finish

mkdir -p "/etc/systemd/system/cockpit.socket.d"
echo '[Socket]
ListenStream=/data/AppData/share/sockets/cockpit.sock
ExecStartPost=
ExecStopPost=
' >"/etc/systemd/system/cockpit.socket.d/listen-socket.conf"

systemctl daemon-reload
