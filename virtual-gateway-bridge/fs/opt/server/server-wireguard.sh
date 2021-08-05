#!/usr/bin/env bash

set -Eeuo pipefail

function x() {
	echo "$*" >&2
	"$@"
}

declare -r DEV=wg_bridge

if ip link show $DEV &>/dev/null; then
	x ip link del $DEV
fi

x ip link add dev $DEV type wireguard
x ip link set $DEV mtu 1100
x ip address add "10.233.222.1" dev $DEV

echo -n "$KEY_PRIVATE" >/tmp/keyfile

x wg set $DEV listen-port "${WIREGUARD_LISTEN_PORT}" private-key /tmp/keyfile
x wg set $DEV peer "$CLIENT_PUB" \
	allowed-ips "10.233.222.2" \
	persistent-keepalive 25

x ip link set up dev $DEV
x ip route add "10.233.222.2" dev $DEV

trap "echo wireguard close ; ip link del $DEV; exit 0" SIGUSR1

while :; do
	sleep infinity &
	wait $!
done

echo "script killed!"
exit 1
