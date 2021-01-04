#!/usr/bin/env bash

set -Eeuo pipefail

echo "Mount data volume"
mount /dev/xvda1 /data

exec /usr/bin/bitcoind \
	-conf=/etc/bitcoin/bitcoin.conf \
	"$@"
