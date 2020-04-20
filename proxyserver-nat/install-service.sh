#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + PASSWORD p/pass "udp2raw的密码"
arg_string + TITLE t/title "本服务器的名称"
arg_string + IP_NUMBER n "本服务器的IP"
arg_finish "$@"

info "upload settings to router..."

SCRIPT="
TITLE='WireguardProxyServer$TITLE'
IP_NUMBER='$IP_NUMBER'
PASSWORD='$PASSWORD'
$(<scripts/router_script.sh)
"
echo "$SCRIPT" | ssh router.home.gongt.me bash > /tmp/load-keys.sh
source /tmp/load-keys.sh

echo -ne "\e[2mKEY_ROUTER_PUBLIC=$KEY_ROUTER_PUBLIC
KEY_PRIVATE=$KEY_PRIVATE
KEY_SHARE=$KEY_SHARE
\e[0m"

info "remote wireguard keys created."

create_unit gongt/proxyserver
unit_podman_image gongt/proxyserver-nat
unit_unit Description "翻墙服务器"
unit_depend network-online.target
unit_podman_arguments --network=bridge0 --mac-address=86:13:02:8F:76:2B --dns=127.0.0.1
unit_podman_arguments --cap-add=NET_ADMIN $(
	safe_environment \
		"KEY_ROUTER_PUBLIC=${KEY_ROUTER_PUBLIC}" \
		"KEY_PRIVATE=${KEY_PRIVATE}" \
		"KEY_SHARE=${KEY_SHARE}" \
		"IP_NUMBER=${IP_NUMBER}" \
		"PASSWORD=${PASSWORD}"
)
unit_finish

systemctl daemon-reload
systemctl enable proxyserver.service
