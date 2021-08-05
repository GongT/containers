#!/usr/bin/env bash

set -Eeuo pipefail

NEXT_PORT=$EXPOSE_PORT
echo -n "[init] client [>>>]" >&2

if [[ "$NO_UDP2RAW" ]]; then
	:
else
	echo -n " --> $NEXT_PORT:[raw]" >&2
	export UDP2RAW_LISTEN_PORT=$NEXT_PORT
	NEXT_PORT=$(random_port)
	export UDP2RAW_CONNECT_PORT="$NEXT_PORT"
fi

if [[ "$NO_UDPSPEEDER" ]]; then
	:
else
	echo -n " --> $NEXT_PORT:[speed]" >&2
	export SPEEDER_LISTEN_PORT=$NEXT_PORT
	NEXT_PORT=$(random_port)
	export SPEEDER_CONNECT_PORT="$NEXT_PORT"
fi

echo " --> $NEXT_PORT:[wireguard]" >&2
export WIREGUARD_LISTEN_PORT=$NEXT_PORT
