#!/usr/bin/env bash

set -Eeuo pipefail

function die() {
	echo "$*" >&2
	exit 1
}

declare -rx RESOLV_CONF="/etc/resolv.conf"

IP=$(command -v ip)
function ip() {
	echo " + $IP -$NET_TYPE $*" >&2
	"$IP" "-$NET_TYPE" "$@"
}

update_addresses() {
	local ADDR OLD_ADDR
	ADDR=$(format_ip_address)
	OLD_ADDR=$(format_oldip_address)
	if [[ ! $ADDR ]]; then
		die "no ip from dhcp"
	fi
	if [[ "$OLD_ADDR" ]] && [[ $OLD_ADDR != "$ADDR" ]]; then
		remove_ip_address
	fi

	if ! ip addr show dev "$interface" | grep -- "$ADDR" &>/dev/null; then
		set_ip_address
	fi
}

resolvconf() {
	local -a DNS_ARR
	mapfile -t DNS_ARR < <(get_received_dns_servers)
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

echo "SCRIPT: $reason" >&2
case "$reason" in
PREINIT | PREINIT6)
	if ! ip link show eth0 | grep -q 'state UP'; then
		ip link set dev "$interface" up
		while ! ip link show eth0 | grep -q 'state UP'; do
			sleep 1
		done
	fi
	;;
RENEW | REBIND | RENEW6 | REBIND6)
	dump_env
	update_all
	call_ddns
	;;
EXPIRE | RELEASE | STOP | EXPIRE6 | RELEASE6 | STOP6)
	remove_ip_address
	;;
BOUND | REBOOT | BOUND6)
	dump_env
	update_all
	bash /opt/wait-net/delete.sh "$NET_TYPE"
	call_ddns
	;;
DEPREF6)
	if [[ "${cur_ip6_prefixlen}" ]]; then
		ip addr change "${cur_ip6_address}/${cur_ip6_prefixlen}" \
			dev "${interface}" scope global preferred_lft 0
	fi
	;;
FAIL)
	die "dhclient failed to get a DHCP lease"
	;;
TIMEOUT)
	die "dhclient timeout"
	;;
esac
