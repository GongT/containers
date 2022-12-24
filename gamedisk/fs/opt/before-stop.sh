#!/usr/bin/env bash

set -Eeuo pipefail

echo "stopping..."

x /usr/sbin/tgtadm --op update --mode sys --name State -v offline
x /usr/sbin/tgt-admin --update ALL -c /dev/null
x /usr/sbin/tgtadm --op delete --mode system

echo "successfully finish tgtd service."
