#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string UDP2RAW_PASSWORD p/pass "udp2raw的密码"
arg_string _UDP2RAW_MODE m/mode "udp2raw的模式（可选: icmp/udp/faketcp）"
arg_string + CLIENT_NAME t/title "客户端ID"
arg_string + IP_NUMBER n "客户端的IP"
arg_finish "$@"

info "upload settings to router..."

SCRIPT="
TITLE='WireguardProxyClient$CLIENT_NAME'
IP_NUMBER='$IP_NUMBER'
UDP2RAW_PASSWORD='$UDP2RAW_PASSWORD'
UDP2RAW_MODE='$_UDP2RAW_MODE'
$(< scripts/router_script.sh)
"
echo "$SCRIPT" | ssh router.home.gongt.me bash > /tmp/load-keys.sh
source /tmp/load-keys.sh

info "upload settings to router - OK"

create_pod_service_unit gongt/proxyclient
unit_unit Description "Proxy Client With Nginx:3270 And Privoxy:3271 And Dnsmasq:53"
if [[ "$UDP2RAW_PASSWORD" ]]; then
	unit_start_notify output "<service started signal>"
else
	unit_start_notify sleep 3
fi
POSTSTART_SCRIPT=$(install_script scripts/reload_dnsmasq.sh)
unit_hook_poststart "$POSTSTART_SCRIPT"
unit_depend network-online.target
unit_fs_bind config/proxyclient /config
network_use_bridge 3271
add_network_privilege
unit_podman_arguments $(
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
unit_body ExecReload '/usr/bin/podman exec proxyclient bash -c "killall -s SIGHUP dnsmasq"'
unit_finish

echo 'resolv-file=/tmp/dnsmasq-resolv-proxy.conf' | write_file '/etc/dnsmasq.d/proxy-hosts.conf'

echo '[Service]
ExecStartPre=/usr/bin/touch /tmp/dnsmasq-resolv-proxy.conf
PrivateTmp=no
' | write_file "/etc/systemd/system/dnsmasq.service.d/proxy.conf"
