#!/usr/bin/env bash

set -Eeuo pipefail

if [[ "$IPV6" ]]; then
	LISTEN="[::]"
else
	LISTEN="0.0.0.0"
fi

exec udp2raw_amd64 \
	--disable-color \
	--seq-mode 2 \
	--cipher-mode xor \
	--auth-mode simple \
	-s --keep-rule \
	-l "$LISTEN:14514" \
	-r 127.0.0.1:50154 \
	--raw-mode icmp \
	--retry-on-error \
	-a