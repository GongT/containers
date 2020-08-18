#!/usr/bin/env bash

set -Eeuo pipefail

if ! [[ -e "$DISK_TO_USE" ]]; then
	ls -l "$(dirname "$DISK_TO_USE")" || true
	echo "required disk did not exists! [$DISK_TO_USE]" >&2
	exit 233
fi

echo "
<target iqn.2020-08.me.gongt:$(basename $DISK_TO_USE)>
	backing-store $DISK_TO_USE
	initiator-name iqn.1991-05.com.microsoft:shabao-desktop
#	incominguser GongT Az1xNPdf0X
</target>
" > /etc/tgt/conf.d/disk.conf

function x() {
	echo " + $*"
	"$@"
}

export TGTD_CONFIG=/etc/tgt/tgtd.conf
/usr/sbin/tgtd -f &
PID=$!

echo "tgtd started as pid $PID"

sleep 5
x /usr/sbin/tgtadm --op update --mode sys --name State -v offline
x /usr/sbin/tgt-admin -e -c $TGTD_CONFIG
x /usr/sbin/tgtadm --op update --mode sys --name State -v ready

echo "tgtd configured"

function handle_quit() {
	echo "receive sigint"

	x /usr/sbin/tgtadm --op update --mode sys --name State -v offline
	x /usr/sbin/tgt-admin --update ALL -c /dev/null
	x /usr/sbin/tgtadm --op delete --mode system

	echo "successfully finish tgtd service."
	exit 0
}

trap handle_quit INT
wait $!

echo "wait finished. stopping..."
