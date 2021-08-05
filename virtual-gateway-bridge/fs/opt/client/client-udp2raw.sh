#!/usr/bin/env bash

set -Eeuo pipefail

if [[ "$IPV6" ]]; then
	TYPE_ARG="AAAA"
else
	TYPE_ARG="A"
fi

declare -i TRY=0
while ! dig "$REMOTE_SERVER" "$TYPE_ARG" &>/dev/null; do
	TRY+=1
	if [[ $TRY -le 3 ]]; then
		echo "failed lookup!"
		sleep 5
	else
		echo "can not lookup name in 15s"
		exit 1
	fi
done

REMOTE=$(dig +short "$REMOTE_SERVER" "$TYPE_ARG" | head -1)
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
