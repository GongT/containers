#!/usr/bin/env bash
set -Eeuo pipefail

function format_ip_address() {
	echo "$new_ip_address/$new_subnet_mask"
}
function format_oldip_address() {
	if [[ "${old_ip_address:-}" ]]; then
		if [[ "${old_subnet_mask:-}" ]]; then
			echo "$old_ip_address/$old_subnet_mask"
		else
			echo "$old_ip_address"
		fi
	fi
}

function set_ip_address() {
	local BC=()
	if [[ "${new_broadcast_address:-}" ]]; then
		BC=(broadcast "$new_broadcast_address")
	fi
	ip addr replace "$(format_ip_address)" "${BC[@]}" dev "$interface"
}
remove_ip_address() {
	local OLD
	OLD=$(format_oldip_address)
	if [[ "${OLD}" ]]; then
		ip addr del "${OLD}" dev "${interface}" || :
	fi
}
function update_routes() {
	local -a ROUTE_ARR=($new_routers)
	for I in "${ROUTE_ARR[@]}"; do
		echo "  [R] :$I:"
	done
	local -r ROUTE="${ROUTE_ARR[0]}"
	if [[ ! $ROUTE ]]; then
		die "no route from dhcp"
	fi

	if ip route show | grep '^default' | grep "$ROUTE" &>/dev/null; then
		echo "[ROUTE] no change ($ROUTE)"
		return
	fi

	ip route del default &>/dev/null || true
	ip route add default via "$ROUTE" dev "$interface" metric 1
}

function get_received_dns_servers() {
	local I
	for I in $new_domain_name_servers; do
		echo "$I"
	done
}
