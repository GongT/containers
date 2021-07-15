#!/usr/bin/env bash

set -Eeuo pipefail

if [[ "$IPV6" ]]; then
	TYPE_ARG="-type=AAAA"
else
	TYPE_ARG="-type=A"
fi

declare -i TRY=0
while ! nslookup "${TYPE_ARG}" "$REMOTE_SERVER"; do
	TRY+=1
	if [[ $TRY -le 3 ]]; then
		echo "failed lookup!"
		sleep 5
	else
		echo "can not lookup name in 15s"
		exit 1
	fi
done

REMOTE=$(nslookup "${TYPE_ARG}" "$REMOTE_SERVER" | tail -n+3 | grep Address: | head -1 | awk '{print $2}')
if [[ "$IPV6" ]]; then
	IP="[$REMOTE]"
else
	IP="$REMOTE"
fi

if [[ ! ${IP:-} ]]; then
	echo "no valid address for $REMOTE_SERVER" >&2
	exit 1
fi

exec udp2raw_amd64 \
	--disable-color \
	--seq-mode 2 \
	--cipher-mode xor \
	--auth-mode simple \
	-c \
	-l 127.0.0.1:22345 \
	-r "$IP:14514" \
	--raw-mode icmp \
	--retry-on-error \
	-a
