#!/usr/bin/env bash

set -Eeuo pipefail

echo "Mount data volume"
mount /dev/xvda1 /data

echo "Start bitcoind"
exec /usr/bin/bitcoind \
	-conf=/etc/bitcoin/bitcoin.conf \
	"-rpcuser=$USERNAME" \
	"-rpcpassword=$PASSWORD" \
	"$@"
