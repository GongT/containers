#!/usr/bin/env bash

set -Eeuo pipefail

exec speederv2_amd64 \
	--disable-color \
	-c \
	-l 127.0.0.1:14516 \
	-r 127.0.0.1:14515 \
	-f 20:10 \
	--mode 1 \
	--mtu 1200
