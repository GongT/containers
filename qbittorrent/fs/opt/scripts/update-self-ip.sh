#!/usr/bin/bash

set -Eeuo pipefail

ipv4=$(curl show-my-ip.gongt.me)
ipv6=$(ip route get to 2001:4860:4860::8888 | grep -oE 'src \S+' | awk '{print $2}')

echo "IP address is [$ipv4] [$ipv6]."

ipv6_escape=$(echo "$ipv6" | sed 's/:/%3A/g')

FIRST=1
if [[ -e /etc/nginx/gen_pass_url.conf ]]; then
	FIRST=
fi

echo "proxy_pass http://10.0.0.1:3271\${request_uri}\${append_arg}port=43081&ipv6=$ipv6_escape&ipv4=$ipv4;" > /etc/nginx/gen_pass_url.conf

mkdir -p /var/log/nginx
if [[ "$FIRST" ]]; then
	nginx -t
else
	systemctl restart nginx
fi
