#!/usr/bin/env bash

set -Eeuo pipefail

function x() {
	echo " + $*"
	"$@"
}

sleep 5
x /usr/sbin/tgtadm --op update --mode sys --name State -v offline
x /usr/sbin/tgt-admin -e -c "$TGTD_CONFIG"
x /usr/sbin/tgtadm --op update --mode sys --name State -v ready

echo "tgtd configured"
