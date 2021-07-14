#!/usr/bin/env bash

set -Eeuo pipefail

if [[ "${REMOTE_SERVER:-}" ]]; then
	MODE=client
else
	MODE=server
fi

mkdir -p /opt/start
for I in udp2raw udpspeeder wireguard; do
	cp "/opt/$MODE/$MODE-$I.sh" "/opt/start/$I.sh"
done

exec /sbin/init
