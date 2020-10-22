#!/usr/bin/env bash
set -Eeuo pipefail

function format_ip_address() {
	echo "$ipv6"
}

function set_ip_address() {
	ip addr add "$ipv6" dev "$interface"
}

function update_routes() {
	ip route add default dev "$interface" metric 1 &>/dev/null || true
}
