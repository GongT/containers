#!/usr/bin/env bash

set -Eeuo pipefail

function die() {
	echo "$*" >&2
	exit 1
}

if [[ "${INTERFACE_NAME+found}" != found ]] || [[ "${NET_NAMESPACE+found}" != found ]]; then
	echo "INTERFACE_NAME=${INTERFACE_NAME+found}"
	echo "NET_NAMESPACE=${NET_NAMESPACE+found}"
	die "Invalid call"
fi

if ! ip netns list 2>&1 | grep -q -- "$NET_NAMESPACE"; then
	ip netns add "$NET_NAMESPACE" || die "Failed create network namespace"
fi

set -x
if ip link show "$INTERFACE_NAME" 2>&1 | grep -q -- "state DOWN"; then
	ip link set "$INTERFACE_NAME" netns "$NET_NAMESPACE" || die "Failed move network interface into namespace"

	echo "network namespace setup complete"
else
	if ip netns exec "$NET_NAMESPACE" ip link show "$INTERFACE_NAME" &> /dev/null; then
		echo "network namespace already setup"
	else
		ip netns exec "$NET_NAMESPACE" ip link show "$INTERFACE_NAME" || true
		die "no interface (down state) named $INTERFACE_NAME"
	fi
fi
