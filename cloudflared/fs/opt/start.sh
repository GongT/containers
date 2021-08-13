#!/usr/bin/env bash

set -Eeuo pipefail

function x() {
	echo "$*" >&2
	exec "$@"
}

NAME="${1:-}"

if [[ ! $NAME ]]; then
	echo "no argument!" >&2
	exit 233
fi

if [[ $NAME == bash ]]; then
	exec bash --login -i
fi

if [[ ! -e /root/.cloudflared/config.yaml ]]; then
	echo "config file did not exists, you need run debug mode, and use cloudflared login" >&2
	exit 233
fi

if ! cloudflared tunnel info "$NAME"; then
	echo "tunnel $NAME did not exists, you need run debug mode, and use cloudflared tunnel create/route, and modify config.yaml manually" >&2
	exit 233
fi

if [[ "${PROXY:-}" ]]; then
	echo "using proxy $PROXY" >&2
	function exe() {
		export http_proxy="$PROXY" https_proxy="$PROXY"
		x proxychains "$@"
	}
else
	echo "no using proxy" >&2
	function exe() {
		export http_proxy="" https_proxy=""
		x "$@"
	}
fi

exe cloudflared tunnel run --log-directory /var/log/cloudflared "$NAME"
