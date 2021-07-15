#!/usr/bin/env bash

set -Eeuo pipefail

exec speederv2_amd64 \
	--disable-color \
	-c \
	-l 127.0.0.1:50154 \
	-r 127.0.0.1:50155 \
	-f 20:10 \
	--mode 0 \
	--mtu 1200
