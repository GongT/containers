#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string UDP2RAW_PASSWORD p/pass "udp2raw的密码"
arg_string _UDP2RAW_MODE m/mode "udp2raw的模式（可选: icmp/udp/faketcp）"
arg_string + CLIENT_NAME t/title "客户端ID"
arg_string + IP_NUMBER n "客户端的IP"
arg_finish

info "upload settings to router..."

SCRIPT="
TITLE='WireguardProxyClient$CLIENT_NAME'
IP_NUMBER='$IP_NUMBER'
UDP2RAW_PASSWORD='$UDP2RAW_PASSWORD'
UDP2RAW_MODE='$_UDP2RAW_MODE'
$(<scripts/router_script.sh)
"
echo "$SCRIPT" | ssh router bash >/tmp/load-keys.sh
source /tmp/load-keys.sh

info "upload settings to router - OK"

ENV_PASS=$(
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

create_pod_service_unit gongt/proxyclient

unit_podman_image gongt/proxyclient
unit_unit Description "proxy client with http(3271) and dns(53)"
# unit_podman_image_pull never
if [[ "$UDP2RAW_PASSWORD" ]]; then
	unit_start_notify output "<service started signal>"
else
	unit_start_notify sleep 3
fi
unit_depend network-online.target
unit_fs_bind config/proxyclient /config
unit_podman_arguments --dns=h.o.s.t
network_use_nat 3271/tcp 35353:53/udp
systemd_slice_type normal
add_network_privilege
unit_podman_arguments "$ENV_PASS"
unit_body ExecReload '/usr/bin/podman exec proxyclient bash -c "killall -s SIGHUP dnsmasq"'

healthcheck "3m" 2 "bash /opt/hc.sh"
healthcheck_start_period 30s
healthcheck_timeout 60s

unit_finish
