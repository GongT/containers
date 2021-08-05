#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string WG_KEY_PRIVATE pk1 "本地wireguard私钥"
arg_string WG_KEY_PRIVATE_SERVER pk2 "服务器wireguard私钥"
arg_string REMOTE_SERVER remote "服务器地址"
arg_string EXPOSE_PORT=14514 remote-port "服务器端口"
arg_string WIREGUARD_MTU=1400 mtu "wireguard接口的MTU"
arg_flag IPV6 6 "使用IPv6而禁用IPv4"
arg_flag NO_UDP2RAW no-raw "禁用udp2raw"
arg_flag NO_UDPSPEEDER no-speed "禁用udpspeeder"
arg_finish "$@"

if [[ "$WG_KEY_PRIVATE" ]]; then
	info "客户端：使用参数私钥"
	KEY_PRIVATE="$WG_KEY_PRIVATE"
else
	info "客户端：生成私钥"
	KEY_PRIVATE=$(wg genkey)
fi
if [[ "$WG_KEY_PRIVATE_SERVER" ]]; then
	info "服务器：使用参数私钥"
	KEY_PRIVATE_SRV="$WG_KEY_PRIVATE_SERVER"
else
	info "服务器：生成私钥"
	KEY_PRIVATE_SRV=$(wg genkey)
fi

create_pod_service_unit gongt/virtual-gateway-bridge
unit_unit Description "bridge remote http/https connection to local"

if [[ ${REMOTE_SERVER:-} ]]; then
	info "客户端模式"
	SERVER_PUB=$(echo "$KEY_PRIVATE_SRV" | wg pubkey)
	ENV_PASS=$(
		safe_environment \
			"KEY_PRIVATE=$KEY_PRIVATE" \
			"SERVER_PUB=$SERVER_PUB" \
			"REMOTE_SERVER=$REMOTE_SERVER" \
			"EXPOSE_PORT=$EXPOSE_PORT" \
			"IPV6=$IPV6" \
			"NO_UDP2RAW=$NO_UDP2RAW" \
			"NO_UDPSPEEDER=$NO_UDPSPEEDER" \
			"WIREGUARD_MTU=$WIREGUARD_MTU"
	)
	network_use_gateway
else
	info "服务器模式"
	CLIENT_PUB=$(echo "$KEY_PRIVATE" | wg pubkey)
	ENV_PASS=$(
		safe_environment \
			"KEY_PRIVATE=$KEY_PRIVATE_SRV" \
			"CLIENT_PUB=$CLIENT_PUB" \
			"EXPOSE_PORT=$EXPOSE_PORT" \
			"IPV6=$IPV6" \
			"NO_UDP2RAW=$NO_UDP2RAW" \
			"NO_UDPSPEEDER=$NO_UDPSPEEDER" \
			"WIREGUARD_MTU=$WIREGUARD_MTU"
	)
	network_use_host
fi

add_network_privilege
unit_podman_arguments "$ENV_PASS"
# unit_start_notify output "start worker process"
# unit_body Restart always
healthcheck "10s" "12" "/opt/hc.sh"
unit_finish
