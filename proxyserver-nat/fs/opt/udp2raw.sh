#!/bin/bash

set -Eeuo pipefail

echo " * ROUTER_PORT=$ROUTER_PORT" >&2

while true; do
	if [[ -e /run/remote_host_ip ]]; then
		break
	fi
	sleep 3
	echo " * wait /run/remote_host_ip to exists..." >&2
done
echo "Wait ok." >&2

echo "<service started signal>"

# loop run udp2raw server
while true; do
	ROUTER_IP=$(</run/remote_host_ip)
	echo " * ROUTER_IP=$ROUTER_IP" >&2
	udp2raw --retry-on-error --disable-color --raw-mode "$UDP2RAW_MODE" --key "$UDP2RAW_PASSWORD" \
		-c -l 127.0.0.1:9999 -r "$ROUTER_IP:$ROUTER_PORT" &
	LAST_PROCESS_ID=$!
	echo "PID: $LAST_PROCESS_ID" >&2

	sleep 2

	echo "$LAST_PROCESS_ID" >/run/udp2raw.pid
	wait $LAST_PROCESS_ID

	echo "Process Exit!" >&2
	if [[ $? -eq 127 ]]; then
		echo "Failed to start udp2raw" >&2
		exit 1
	fi
done
