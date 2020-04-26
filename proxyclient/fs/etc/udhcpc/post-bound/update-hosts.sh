#!/bin/bash

if [[ -n "$ipv6" ]] ; then
	exit 0
fi

echo "My Self Ip Is: $ip"

echo "
$ip proxy-server.local proxy-server
" > /tmp/dnsmasq-hosts/proxy_hosts
