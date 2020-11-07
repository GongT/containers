#!/usr/bin/env bash
set -Eeuo pipefail

function format_ip_address() {
	echo "$new_ip6_address/$new_ip6_prefixlen"
}
function format_oldip_address() {
	if [[ "${old_ip6_address:-}" ]]; then
		if [[ "${old_ip6_prefixlen:-}" ]]; then
			echo "$old_ip6_address/$old_ip6_prefixlen"
		else
			echo "$old_ip6_address"
		fi
	fi
}

function set_ip_address() {
	local ADDR i STATE
	ADDR=$(format_ip_address)
	ip addr replace "$ADDR" dev "$interface" scope global valid_lft "${new_max_life}" preferred_lft "${new_preferred_life}"
	for i in $(seq 5); do
		sleep 1
		STATE=$(ip addr show dev "$interface" | grep "$ADDR")
		if ! [[ "$STATE" ]]; then
			echo "Failed, address can not add" >&2
			exit 3
		fi
		if [[ $STATE == *dadfailed* ]]; then
			echo "Failed, address used somewhere" >&2
			ip addr del "$ADDR" dev "${interface}"
			exit 3
		fi
		if [[ $STATE != *tentative* ]]; then
			echo "Address assigned" >&2
			break
		fi
	done
}
remove_ip_address() {
	local OLD
	OLD=$(format_oldip_address)
	if [[ "$OLD" ]]; then
		ip addr del "$OLD" dev "${interface}" || :
	fi
}
function update_routes() {
	# ip route add default dev "$interface" metric 1 &>/dev/null || true
	:
}
function get_received_dns_servers() {
	local I
	for I in $new_dhcp6_name_servers; do
		echo "$I"
	done
}
