#!/usr/bin/env bash

set -Eeuo pipefail

set -x

ip link show
ip link set dev "$INTERFACE_NAME" mtu 9000

ip addr replace 127.0.0.1/8 dev lo
# ip addr replace ::1/128 dev lo

ip route flush dev "$INTERFACE_NAME"
ip addr flush dev "$INTERFACE_NAME"

ip addr add "192.211.1.1/24" dev "$INTERFACE_NAME"
ip link set dev "$INTERFACE_NAME" up
for I in $(seq 2 10); do
	ip link add link "$INTERFACE_NAME" name "vlan.$I" address "00:04:c9:52:$(printf '%02x\n' "$I"):6e" type vlan id "$I"
	ip addr add "192.211.$I.1/24" dev "vlan.$I"
	ip link set up "vlan.$I"
done

# for I in $(seq 2 10); do
# 	 ip link del "vlan.$I"
# done

# ip link set dev "$INTERFACE_NAME" up
# for I in $(seq 1 10); do
# 	ip addr add "192.211.$I.1/24" dev "$INTERFACE_NAME"
# done

# ip addr replace fdfb:fb00:fb00::1/64 dev "$INTERFACE_NAME"
# ip route replace fdfb:fb00:fb00::/64 dev "$INTERFACE_NAME"
# echo "fdfb:fb00:fb00::1 main" > /etc/hosts
echo "192.211.0.1 main" >/etc/hosts

exec dnsmasq --no-daemon
# exec dnsmasq --keep-in-foreground
