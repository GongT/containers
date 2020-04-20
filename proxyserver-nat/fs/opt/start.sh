#!/bin/bash

set -Eeuo pipefail

function resolveIp() {
	# echo " +++ nslookup -type=A $1 ${2-8.8.8.8}" >&2
	local X=$(nslookup -type=A "$1" "${2-8.8.8.8}" | grep Address: | tail -n1 | sed 's/Address: //g')
	if [[ -z "$X" ]] ; then
		return 1
	fi
	echo -n $X
}

declare -r ROUTER_PORT=$(( 49300 + $IP_NUMBER ))
echo "ROUTER_PORT=$ROUTER_PORT"

LAST_PROCESS_ID=""
function respawn() {
	if [[ $LAST_PROCESS_ID ]] ; then
		kill "$LAST_PROCESS_ID"
		wait "$LAST_PROCESS_ID"
	fi
	udp2raw --retry-on-error --disable-color --raw-mode icmp --key "$PASSWORD" \
		-c -l 127.0.0.1:9999 -r "$1:$ROUTER_PORT" &
	LAST_PROCESS_ID=$!
}

function info() {
	echo " ====== $*" >&2
}

# set basic network
ip addr add 10.100.231.213/24 dev eth0
ip route add default via 10.100.231.254
info "basic network setup ok."

# set wireguard
echo "$KEY_PRIVATE" >/tmp/keyfile
echo "$KEY_SHARE" >/tmp/psk

DEV=wg0
ip link add dev $DEV type wireguard
ip address add "10.233.233.$IP_NUMBER" dev $DEV

wg set $DEV listen-port 9000 private-key /tmp/keyfile
wg set $DEV peer "$KEY_ROUTER_PUBLIC" \
			allowed-ips "10.233.233.1" \
			preshared-key /tmp/psk \
			persistent-keepalive 25 \
			endpoint "127.0.0.1:9999"

ip link set up dev $DEV
ip route add "10.233.233.1" dev $DEV

# loop run udp2raw server
SAVED_ROUTER_IP=""
while true; do
	ROUTER_IP=$(resolveIp router.home.gongt.me)
	info "resolve router.home.gongt.me is: $ROUTER_IP"

	if [[ "$SAVED_ROUTER_IP" == "$ROUTER_IP" ]]; then
		info "ip un-changed: $ROUTER_IP"
	else
		info "ip has change: $SAVED_ROUTER_IP ==>> $ROUTER_IP"
		SAVED_ROUTER_IP="$ROUTER_IP"
		respawn "$ROUTER_IP"
	fi
	sleep 60
done
