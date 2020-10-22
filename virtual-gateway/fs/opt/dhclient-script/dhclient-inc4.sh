#!/usr/bin/env bash
set -Eeuo pipefail

function format_ip_address() {
	echo "$ip/$mask"
}

function set_ip_address() {
	local BC=()
	if [[ "${broadcast:-}" ]]; then
		BC=(broadcast "$broadcast")
	fi
	ip addr add "$ip/$mask" "${BC[@]}" dev "$interface"
}

function update_routes() {
	local -a ROUTE_ARR=($router)
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
