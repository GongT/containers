#!/usr/bin/env bash
set -Eeuo pipefail

function format_ip_address() {
	echo "$new_ip6_address"
}

function set_ip_address() {
	ip addr add "$new_ip6_address" dev "$interface"
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
