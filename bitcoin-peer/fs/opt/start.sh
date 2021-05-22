#!/usr/xbin/env bash

set -Eeuo pipefail

echo "Mount data volume"
mount /dev/xvda1 /data

sed -i "s/__PRC_USERNAME__/$USERNAME/g" /etc/bitcoin/bitcoin.conf
sed -i "s/__PRC_PASSWORD__/$PASSWORD/g" /etc/bitcoin/bitcoin.conf

echo "Start bitcoind"
exec /usr/bin/bitcoind \
	-conf=/etc/bitcoin/bitcoin.conf \
	"-rpcuser=$USERNAME" \
	"-rpcpassword=$PASSWORD" \
	"$@"
