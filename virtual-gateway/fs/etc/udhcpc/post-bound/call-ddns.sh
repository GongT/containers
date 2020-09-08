#!/bin/bash

if [[ -z "$ipv6" ]] ; then
	exit 0
fi

rm -f /opt/wait-ip-exists.lock

echo "Call DDNS Script By post-bound.">&2
source /etc/periodic/15min/run-ddns
