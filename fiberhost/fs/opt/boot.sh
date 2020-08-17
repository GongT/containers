#!/usr/bin/env bash

set -Eeuo pipefail

set -x

ip link show

ip addr replace fdfb:fb00:fb00::1/64 dev "$INTERFACE_NAME"
ip addr replace 192.211.66.1/24 dev "$INTERFACE_NAME"
ip link set "$INTERFACE_NAME" up
# ip route replace fdfb:fb00:fb00::/64 dev "$INTERFACE_NAME"
echo "fdfb:fb00:fb00::1 main" > /etc/hosts

exec dnsmasq --keep-in-foreground
