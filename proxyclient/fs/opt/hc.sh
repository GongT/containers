#!/bin/bash

set -Eeuo pipefail

function die() {
	echo "$*" >&2
	return 1
}

PING_RESULT=$(ping -4 -A -c5 -w5 10.233.233.1 || true | grep 'packets transmitted')
if echo "$PING_RESULT" | grep -q "0 packets transmitted"; then
	die "ping failed (all packat lost)"
fi
echo "wireguard interface ping success"

nslookup -retry=6 -timeout=5 -type=A www.google.com 127.0.0.1 \
	| tail -n +3 \
	| grep -q Address: \
	|| die "can not resolve google.com"
echo "dns resolve success"

curl -s --max-time 10 https://google.com >/dev/null || die "failed request google homepage directly"
echo "network access success"

curl -s --max-time 10 -x http://127.0.0.1:3271 https://google.com >/dev/null || die "failed request google homepage through proxy"
echo "http proxy server ok"
