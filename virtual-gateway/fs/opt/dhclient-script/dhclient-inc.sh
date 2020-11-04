#!/usr/bin/env bash

set -Eeuo pipefail

function die() {
	echo "$*" >&2
	exit 1
}

declare -rx ACTION="$1"
declare -rx RESOLV_CONF="/etc/resolv.conf"

IP=$(command -v ip)
function ip() {
	echo " + $IP -$NET_TYPE $*" >&2
	"$IP" "-$NET_TYPE" "$@"
}

declare -r LAST_FILE="/tmp/last-addr-$NET_TYPE"
remove_ip_address() {
	if [[ -e $LAST_FILE ]]; then
		ip addr del "$(<"$LAST_FILE")" dev "$interface"
		rm -f "$LAST_FILE"
	fi
}

update_addresses() {
	local ADDR
	ADDR=$(format_ip_address)
	if [[ ! $ADDR ]]; then
		die "no ip from dhcp"
	fi

	if ! ip addr show dev "$interface" | grep -- "$ADDR" &>/dev/null; then
		remove_ip_address
		set_ip_address
		echo "$ADDR" >"$LAST_FILE"
	fi
}

resolvconf() {
	local -a DNS_ARR=($dns)
	flock /etc/resolv.conf bash resolve.conf.sh "gateway$NET_TYPE" "${DNS_ARR[@]}"
}

update_all() {
	update_addresses
	update_routes
	resolvconf
}

call_ddns() {
	bash "/opt/ddns/v$NET_TYPE.sh"
}

function dump_env() {
	echo "------------------------------------------"
	env
	echo "------------------------------------------"
}

echo "SCRIPT: $ACTION" >&2
case "$ACTION" in
renew)
	dump_env
	update_all
	call_ddns
	;;
deconfig)
	ip route flush default dev "$interface"
	remove_ip_address
	;;
bound)
	dump_env
	ip link set dev "$interface" up
	update_all

	bash /opt/wait-net/delete.sh "$NET_TYPE"
	call_ddns
	;;
leasefail)
	die "udhcpc failed to get a DHCP lease"
	;;
nak)
	die "udhcpc received DHCP NAK"
	;;
*)
	die "Error: this script should be called from udhcpc"
	;;
esac
