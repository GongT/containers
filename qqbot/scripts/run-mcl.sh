#!/usr/bin/env bash

set -Eeuo pipefail

java -jar mcl.jar --disable-script announcement
java -jar mcl.jar --log-level 0 --dry-run

if java -version 2>&1 | grep -qi openjdk; then
	WANT_NUM=6
else
	WANT_NUM=8
fi

ELEMENTS=$(ls libs | wc -l)
if [[ $ELEMENTS -ne $WANT_NUM ]]; then
	ls -lAh libs
	echo "not installed all libs" >&2
	exit 1
fi

echo DONE
