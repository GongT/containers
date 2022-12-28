#!/usr/bin/bash

set -Eeuo pipefail

ARGSTR=''

ipv4=$(dig +short router.home.gongt.me A)
echo "IPv4 address is [$ipv4]."
ARGSTR+="&ipv4=$ipv4"

ipv6r=$(ip route get to 2001:4860:4860::8888 2>/dev/null || true)
if [[ "$ipv6r" ]]; then
	ipv6=$(echo "$ipv6r" | grep -oE 'src \S+' | awk '{print $2}')
	echo "IPv6 address is [$ipv6]."
	ipv6_escape=$(echo "$ipv6" | sed 's/:/%3A/g')
	ARGSTR+="&ipv6=$ipv6_escape"
fi

FIRST=1
if [[ -e /etc/nginx/gen_pass_url.conf ]]; then
	FIRST=
fi

echo "proxy_pass http://10.0.0.1:3271\${request_uri}\${append_arg}port=43081${ARGSTR};" | tee /etc/nginx/gen_pass_url.conf

mkdir -p /var/log/nginx
if [[ "$FIRST" ]]; then
	nginx -t
else
	systemctl restart nginx
fi
