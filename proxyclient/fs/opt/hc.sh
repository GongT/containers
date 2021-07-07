#!/bin/bash

set -Eeuo pipefail

function die() {
	echo -e "\n$*" >&2
	return 1
}

function hc() {
	echo -n "[Step 1] ping 10.233.233.1 with wireguard interface ... "
	PING_RESULT=$(ping -4 -A -c5 -w5 10.233.233.1 || true | grep 'packets transmitted')
	if echo "$PING_RESULT" | grep -q "0 packets transmitted"; then
		die "wireguard VPN failed"
	fi
	echo "success"

	echo -n "[Step 2] resolve www.google.com ... "
	nslookup -retry=6 -timeout=5 -type=A www.google.com 127.0.0.1 \
		| tail -n +2 \
		| grep Address: \
		| head -n 1 \
		|| die "dns not working"

	echo "[Step 3] access china website (www.baidu.com) ... "
	wget -T 10 -O /tmp/hc.direct -Y off http://www.baidu.com || die "failed request baidu homepage directly"
	echo "[Step 3] network access success"

	echo "[Step 4] access world website (www.google.co.jp) through proxy ... "
	export http_proxy="http://127.0.0.1:3271" https_proxy="http://127.0.0.1:3271"
	wget -T 10 -O /tmp/hc.proxy -Y on http://www.google.co.jp || die "failed request google homepage through proxy"
	echo "[Step 4] proxy is ok"
}

if hc; then
	exit 0
fi
echo " == failed retry == "

if hc; then
	exit 0
fi
echo " == failed retry == "

if hc; then
	exit 0
fi
echo " == failed, 3 times == "
