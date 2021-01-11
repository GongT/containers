#!/bin/bash

set -Eeuo pipefail

function uci() {
	echo -e "\e[2m + uci $*\e[0m" >&2
	/sbin/uci "$@"
}

if ! uci get network.wg_proxy.listen_port &>/dev/null; then
	echo "Failed: no network named wg_proxy (or config error) on the router." >&2
	exit 1
fi

echo "KEY_ROUTER_PUBLIC=$(uci get network.wg_proxy.private_key | wg pubkey)"

declare -r WG_PORT=$(uci get network.wg_proxy.listen_port)
declare -r UDP2RAW_PORT=$((49300 + IP_NUMBER))
if [[ "${UDP2RAW_PASSWORD}" ]]; then
	UDP2RAW_MODE=${UDP2RAW_MODE-icmp}

	if [[ $(uci get "udp2raw.$UDP2RAW_PORT") != "map" ]]; then
		CFG=$(uci add udp2raw map)
		uci rename "udp2raw.$CFG=$UDP2RAW_PORT"
	fi
	uci set "udp2raw.$UDP2RAW_PORT.mode=$UDP2RAW_MODE"
	uci set "udp2raw.$UDP2RAW_PORT.connect=$WG_PORT"
	uci set "udp2raw.$UDP2RAW_PORT.passwd=$UDP2RAW_PASSWORD"

	echo "UDP2RAW_MODE=$UDP2RAW_MODE"
	ROUTER_PORT=$UDP2RAW_PORT
else
	if [[ $(uci get "udp2raw.$UDP2RAW_PORT") == "map" ]]; then
		uci delete "udp2raw.$UDP2RAW_PORT"
	fi
	echo "UDP2RAW_MODE="
	ROUTER_PORT=$WG_PORT
fi
echo "ROUTER_PORT=$ROUTER_PORT"

if uci get "network.$TITLE" >&/dev/null; then
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
fi

echo "KEY_PRIVATE=$KEY_PRIVATE"
echo "KEY_SHARE=$KEY_SHARE"
echo "MTU=$(uci get network.wg_proxy.mtu)"

RS1=
if [[ "$(uci changes udp2raw)" ]]; then
	RS1=yes
fi
RS2=
if [[ "$(uci changes network)" ]]; then
	RS2=yes
fi
uci commit
if [[ "$RS1" ]]; then
	echo "Restart/Reload udp2raw" >&2
	/etc/init.d/udp2raw restart
else
	echo "not chage: udp2raw" >&2
fi
if [[ "$RS2" ]]; then
	echo "Restart/Reload network" >&2
	/etc/init.d/network reload
else
	echo "not chage: network" >&2
fi
