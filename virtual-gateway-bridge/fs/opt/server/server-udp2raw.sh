#!/usr/bin/env bash

set -Eeuo pipefail

exec udp2raw_amd64 \
	--disable-color \
	--seq-mode 2 \
	--cipher-mode xor \
	--auth-mode simple \
	-s --keep-rule \
	-l 0.0.0.0:14514 \
	-r 127.0.0.1:50154 \
	--raw-mode icmp \
	--retry-on-error \
	-a
