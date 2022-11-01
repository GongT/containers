#!/usr/bin/env bash

flock -n -E 233 /tmp/ddns-v6-inprogress \
	bash "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/v6lock.sh"
RET=$?

if [[ $RET -eq 233 ]]; then
	echo "(6) DDNS in progress, skip this time." >&2
	exit 0
fi

exit $RET
