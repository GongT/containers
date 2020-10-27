#!/bin/bash

set -Eeuo pipefail

function resolveIp() {
	nslookup -type=A "$1" | tail -n +3 | grep 'Address: ' | sed 's/Address: //g' | head -n1
}

function x() {
	echo " + $*" >&2
	"$@"
}

# set basic network
x ip addr add 10.100.231.213/24 dev eth0
x ip route add default via 10.100.231.254
echo "basic network setup ok." >&2

# set wireguard
echo "$KEY_PRIVATE" >/tmp/keyfile
echo "$KEY_SHARE" >/tmp/psk

declare -r DEV=wg0
x ip link add dev $DEV type wireguard
x ip link set $DEV mtu $MTU
x ip address add "10.233.233.$IP_NUMBER" dev $DEV

x wg set $DEV listen-port 9000 private-key /tmp/keyfile
x wg set $DEV peer "$KEY_ROUTER_PUBLIC" \
	allowed-ips "10.233.233.1" \
	preshared-key /tmp/psk \
	persistent-keepalive 25 \
	endpoint "127.0.0.1:9999"

x ip link set up dev $DEV
x ip route add "10.233.233.1" dev $DEV

declare -r TARGE_HOST="router.home.gongt.me"
SAVED_IP=""

if [[ "$UDP2RAW_PASSWORD" ]]; then
	function action() {
		local NEW_IP="$1"
		echo -n "$NEW_IP" >/run/remote_host_ip

		if [[ -e /run/udp2raw.pid ]]; then
			local pid=$(</run/udp2raw.pid)
			echo "    try kill process: $pid"
			kill -SIGINT $pid || true
		fi
	}
else
	function action() {
		x wg set $DEV peer "$KEY_ROUTER_PUBLIC" endpoint "$1:$ROUTER_PORT"
	}
fi

function run() {
	local IP
	while true; do
		IP=$(resolveIp "$TARGE_HOST")
		if [[ "$IP" ]]; then
			break
		else
			echo " ... Resolve Host Failed: $TARGE_HOST!" >&2
			sleep 1
		fi
	done

	if [[ "$IP" == "$SAVED_IP" ]]; then
		echo "[$(date "+%F %T")] Update ip: no change!" >&2
	else
		echo "[$(date "+%F %T")] Update ip: from '$SAVED_IP' to '$IP'!" >&2
		action "$IP"

		SAVED_IP="$IP"
	fi
}

while true; do
	run
	sleep 120
done
