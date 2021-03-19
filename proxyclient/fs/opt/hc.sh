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

wget -T 10 -O /dev/null -Y off http://www.baidu.com || die "failed request baidu homepage directly"
echo "network access success"

export http_proxy="127.0.0.1:3271" https_proxy="127.0.0.1:3271"
wget -T 10 -O /dev/null -Y on http://www.google.co.jp || die "failed request google homepage through proxy"
echo "http proxy server ok"
