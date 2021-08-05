#!/usr/bin/env bash

set -Eeuo pipefail

if [[ "${REMOTE_SERVER:-}" ]]; then
	MODE=client
else
	MODE=server
fi

read -r lower_port upper_port </proc/sys/net/ipv4/ip_local_port_range
function random_port() {
	shuf -n1 -i "${lower_port}-${upper_port}"
}

source "/opt/$MODE/init-port.sh"

echo "====================================================" >&2
env >&2
echo "====================================================" >&2

if [[ "$NO_UDP2RAW" ]] && [[ "$NO_UDPSPEEDER" ]]; then
	echo "[init] wireguard only mode!" >&2
	exec bash "/opt/$MODE/$MODE-$I.sh"
fi

PARTS=(wireguard)
if ! [[ "$NO_UDP2RAW" ]]; then
	PARTS+=("udp2raw")
fi
if ! [[ "$NO_UDPSPEEDER" ]]; then
	PARTS+=("udpspeeder")
fi

mkdir -p /opt/start
echo "" >/etc/programs
for I in "${PARTS[@]}"; do
	cp "/opt/$MODE/$MODE-$I.sh" "/opt/start/$I.sh"
	cat "/etc/programs-parts/$I" >>/etc/programs
done

exec /sbin/init
