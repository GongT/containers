#!/usr/bin/env bash

set -Eeuo pipefail

function x() {
	echo -e "\e[2m + $*\e[0m" >&2
	"$@"
}

x java -jar mcl.jar --show-repos

x java -jar mcl.jar --boot-only --disable-progress-bar --enable-auto-clear
x java -jar mcl.jar --log-level 0 --dry-run --disable-progress-bar

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
