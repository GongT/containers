#!/usr/bin/env bash

flock -n /tmp/ddns-v6-inprogress bash "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/v6lock.sh" || {
	echo "(6) DDNS in progress, skip this time."
	exit 0
}
