#!/usr/bin/env bash

set -Eeuo pipefail

if ! [[ -e $DISK_TO_USE ]]; then
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
" >/etc/tgt/conf.d/disk.conf
