#!/bin/bash

set -a
source /etc/wireguard/client.conf

/opt/wait-net/wait.sh

while true; do
	/usr/libexec/wireguard-config-client
	sleep 5
done
