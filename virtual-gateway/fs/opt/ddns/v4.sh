#!/usr/bin/env bash

flock -n /tmp/ddns-v4-inprogress bash "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/v4lock.sh" || {
	echo "(4) DDNS in progress, skip this time."
	exit 0
}
