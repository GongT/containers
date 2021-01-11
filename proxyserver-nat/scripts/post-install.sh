#!/bin/sh

die() {
	echo "$*" >&2
	exit 1
}

apk -U add "$@" || die "apk add failed"
rm -rf /etc/dnsmasq.d /etc/dnsmasq.conf
