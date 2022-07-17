#!/usr/bin/env bash

set -Eeuo pipefail

function die() {
	echo "$*" >&2
	exit 1
}

if [[ ! $INTERFACE_NAME ]] || [[ ! $NET_NAMESPACE ]]; then
	die "Invalid call"
fi

if ! ip netns exec "$NET_NAMESPACE" ip link show "$INTERFACE_NAME" 2>&1 | grep -q -- "$INTERFACE_NAME"; then
	echo "namespace not setup"
	exit 0
fi

if ! ip netns exec "$NET_NAMESPACE" ip link set "$INTERFACE_NAME" down &>/dev/null; then
	die "Failed set network interface down"
fi

for I in $(seq 1 10); do
	if ! ip netns exec "$NET_NAMESPACE" ip link del "vlan.$I" &>/dev/null; then
		echo "Failed delete vlan interface $I" >&2
	fi
done

if ip netns exec "$NET_NAMESPACE" ip link set "$INTERFACE_NAME" netns 1; then
	echo "network interface move out complete"
else
	die "failed move interface"
fi
