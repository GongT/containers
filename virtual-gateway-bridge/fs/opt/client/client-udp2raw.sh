#!/usr/bin/env bash

set -Eeuo pipefail

mapfile -t REMOTE_LIST < <(nslookup "$REMOTE_SERVER" | tail -n+3 | grep Address: | awk '{print $2}' | tac)
for REMOTE in "${REMOTE_LIST[@]}"; do
	if ping -c 1 "$REMOTE"; then
		if echo "$REMOTE" | grep ':'; then
			IP="[$REMOTE]"
		else
			IP="$REMOTE"
		fi
		break
	fi
done

if [[ ! ${IP:-} ]]; then
	echo "no address usable for $REMOTE_SERVER" >&2
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
