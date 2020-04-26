#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string   UDP2RAW_PASSWORD p/pass "udp2raw的密码"
arg_string   _UDP2RAW_MODE m/mode "udp2raw的模式（可选: icmp/udp/faketcp）"
arg_string + TITLE t/title "本服务器的名称"
arg_string + IP_NUMBER n "本服务器的IP"
arg_finish "$@"

info "upload settings to router..."

SCRIPT="
TITLE='WireguardProxyServer$TITLE'
IP_NUMBER='$IP_NUMBER'
UDP2RAW_PASSWORD='$UDP2RAW_PASSWORD'
UDP2RAW_MODE='$_UDP2RAW_MODE'
$(<scripts/router_script.sh)
"
echo "$SCRIPT" | ssh router.home.gongt.me bash > /tmp/load-keys.sh
source /tmp/load-keys.sh

info "remote wireguard keys created."

create_unit gongt/proxyserver
unit_podman_image gongt/proxyserver-nat
unit_unit Description "Proxy Server Behind NAT"
if [[ "$UDP2RAW_PASSWORD" ]]; then
	unit_start_notify output "<service started signal>"
else
	unit_start_notify sleep 3
fi
unit_depend network-online.target
unit_fs_bind config/proxy /config
unit_body Restart always
network_use_manual --network=bridge0 --mac-address=86:13:02:8F:76:2B --dns=127.0.0.1
unit_podman_arguments --cap-add=NET_ADMIN $(
	safe_environment \
		"KEY_ROUTER_PUBLIC=${KEY_ROUTER_PUBLIC}" \
		"KEY_PRIVATE=${KEY_PRIVATE}" \
		"KEY_SHARE=${KEY_SHARE}" \
		"IP_NUMBER=${IP_NUMBER}" \
		"UDP2RAW_PASSWORD=${UDP2RAW_PASSWORD}" \
		"ROUTER_PORT=${ROUTER_PORT}" \
		"UDP2RAW_MODE=${UDP2RAW_MODE}" \
		"MTU=${MTU}"
)
unit_finish

systemctl daemon-reload
systemctl enable proxyserver.service
