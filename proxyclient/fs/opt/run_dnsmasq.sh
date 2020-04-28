#!/bin/bash

touch /tmp/hosts

if [[ ! -e /config/dnsmasq.conf ]]; then
	touch /config/dnsmasq.conf
fi
if [[ ! -e /config/addn-hosts ]]; then
	touch /config/addn-hosts
fi

ND='--keep-in-foreground'
# ND='--no-daemon'
exec /usr/sbin/dnsmasq $ND --conf-file=/etc/dnsmasq.conf --pid-file=/run/dnsmasq.pid
