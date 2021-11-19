#!/bin/bash

touch /tmp/hosts

if [[ ! -e /config/dnsmasq.conf ]]; then
	touch /config/dnsmasq.conf
fi
if [[ ! -e /config/addn-hosts ]]; then
	touch /config/addn-hosts
fi

DEFAULT_RESOLVE=223.5.5.5
if [[ -e "/etc/resolv.conf" ]]; then
	DEFAULT_RESOLVE=$(cat /etc/resolv.conf | grep nameserver | tail -n1 | awk '{print $2}')
	if [[ "$DEFAULT_RESOLVE" == 127.0.0.1 ]]; then
		DEFAULT_RESOLVE=223.5.5.5
	fi
	sed -i '/nameserver /d' /etc/resolv.conf
fi
echo "" >> /etc/resolv.conf
echo "nameserver 127.0.0.1" >> /etc/resolv.conf

sed -i "s/1\.1\.1\.1/$DEFAULT_RESOLVE/g" /etc/dnsmasq.conf

ND='--keep-in-foreground'
# ND='--no-daemon'
exec /usr/sbin/dnsmasq $ND --conf-file=/etc/dnsmasq.conf --pid-file=/run/dnsmasq.pid
