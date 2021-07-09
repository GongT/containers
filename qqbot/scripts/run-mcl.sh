#!/usr/bin/env bash

java -jar mcl.jar --disable-script announcement
java -jar mcl.jar --log-level 0 --dry-run

ELEMENTS=$(ls libs | wc -l)
if [[ $ELEMENTS -ne 8 ]]; then
	ls -lAh libs
	echo "not installed all libs" >&2
	exit 1
fi
