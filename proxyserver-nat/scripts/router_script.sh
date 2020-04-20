#!/bin/bash

set -Eeuo pipefail

declare -r ROUTER_PORT=$((49300 + $IP_NUMBER))

echo -n "KEY_ROUTER_PUBLIC="
uci get network.wg_proxy.private_key | wg pubkey

function uci() {
	echo -e "\e[2m + uci $*\e[0m" >&2
	/sbin/uci "$@"
}

WG_PORT=$(uci get network.wg_proxy.listen_port)
if [[ $( uci get "udp2raw.$ROUTER_PORT" ) != "map" ]]; then
	CFG=$( uci add udp2raw map )
	uci rename "udp2raw.$CFG=$ROUTER_PORT"
fi
uci set "udp2raw.$ROUTER_PORT.connect=$WG_PORT"
uci set "udp2raw.$ROUTER_PORT.passwd=$PASSWORD"

if uci get "network.$TITLE" >&/dev/null; then
	uci commit

	echo "using existing network.$TITLE" >&2
	KEY_PRIVATE=$(uci get "network.$TITLE.private_key")
	KEY_SHARE=$(uci get "network.$TITLE.preshared_key")
else
	echo "creating new network.$TITLE" >&2
	CFG=$(uci add network wireguard_wg_proxy)
	uci rename "network.$CFG=$TITLE"

	KEY_PRIVATE=$(wg genkey)
	KEY_SHARE=$(wg genpsk)

	uci set "network.$TITLE.private_key=$KEY_PRIVATE"
	uci set "network.$TITLE.public_key=$(echo "$KEY_PRIVATE" | wg pubkey)"
	uci set "network.$TITLE.preshared_key=$KEY_SHARE"
	uci set "network.$TITLE.route_allowed_ips=1"
	uci set "network.$TITLE.description=$TITLE"
	uci set "network.$TITLE.allowed_ips=10.233.233.$IP_NUMBER"
	uci set "network.$TITLE.persistent_keepalive=25"

	uci commit

	/etc/init.d/network reload
fi

echo "KEY_PRIVATE=$KEY_PRIVATE"
echo "KEY_SHARE=$KEY_SHARE"
