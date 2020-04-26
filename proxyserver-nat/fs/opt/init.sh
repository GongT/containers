#!/bin/bash

if [[ "$UDP2RAW_PASSWORD" ]] ; then
	echo "USE UDP2RAW" >&2
	cat /etc/programs.udp2raw >> /etc/programs
else
	echo "DO NOT USE UDP2RAW" >&2
fi

exec /sbin/init
