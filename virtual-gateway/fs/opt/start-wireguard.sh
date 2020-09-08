#!/bin/bash

set -a
source /etc/wireguard/client.conf

echo "Wait for first connection..."
while [[ -e /opt/wait-ip-exists.lock ]]; do
	sleep 3
done

while true; do
	/usr/libexec/wireguard-config-client
	sleep 5
done
