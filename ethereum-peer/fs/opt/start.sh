#!/usr/bin/env bash

set -Eeuo pipefail

echo "Mount data volume"
mkdir /data
mount /dev/xvda1 /data

echo "Start geth"
exec /usr/local/bin/geth --http --syncmode "light" --datadir /data
