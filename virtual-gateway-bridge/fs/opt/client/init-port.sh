#!/usr/bin/env bash

set -Eeuo pipefail

NEXT_PORT=$EXPOSE_PORT
echo -n "[init] server [<<<]:$NEXT_PORT" >&2

export WIREGUARD_CONNECT_IP="$REMOTE_SERVER"

if [[ "$NO_UDP2RAW" ]]; then
	:
else
	export WIREGUARD_CONNECT_IP=127.0.0.1
	export UDP2RAW_CONNECT_PORT=$NEXT_PORT
	NEXT_PORT=$(random_port)
	export UDP2RAW_LISTEN_PORT="$NEXT_PORT"
	echo -n " <-- [raw]:$NEXT_PORT" >&2
fi

if [[ "$NO_UDPSPEEDER" ]]; then
	:
else
	export WIREGUARD_CONNECT_IP=127.0.0.1
	export SPEEDER_CONNECT_PORT=$NEXT_PORT
	NEXT_PORT=$(random_port)
	export SPEEDER_LISTEN_PORT="$NEXT_PORT"
	echo -n " <-- [speed]:$NEXT_PORT" >&2
fi

export WIREGUARD_CONNECT_PORT=$NEXT_PORT
echo " <-- [wireguard]"
