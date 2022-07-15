#!/usr/bin/env bash

set -Eeuo pipefail

set -x

ip link show
ip set dev "$INTERFACE_NAME" mtu 9000

ip addr replace 127.0.0.1/8 dev lo
# ip addr replace ::1/128 dev lo

ip addr flush dev "$INTERFACE_NAME"
ip link set "$INTERFACE_NAME" up
for I in $(seq 1 10); do
	ip addr add "192.211.$I.1/255.255.255.0" dev "$INTERFACE_NAME"
done
ip route flush dev "$INTERFACE_NAME"
for I in $(seq 1 10); do
	ip route add "192.211.$I.0" dev "$INTERFACE_NAME" src "192.211.$I.1"
done
# ip addr replace fdfb:fb00:fb00::1/64 dev "$INTERFACE_NAME"
# ip route replace fdfb:fb00:fb00::/64 dev "$INTERFACE_NAME"
# echo "fdfb:fb00:fb00::1 main" > /etc/hosts
echo "192.211.66.1 main" >/etc/hosts

exec dnsmasq --no-daemon
# exec dnsmasq --keep-in-foreground
