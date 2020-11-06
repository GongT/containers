#!/bin/sh

die() {
	echo "$*" >&2
	exit 1
}

apk -U add "$@" || die "apk add failed"

cd "$(mktemp -d)" || die "failed mk temp folder"
apk fetch dhclient || die "apk fetch dhclient failed"
tar xf ./*.apk || {
	pwd
	ls -lhA
	die "failed untar apk"
}
cp -r usr / || {
	find . -type f -print
	die "failed copy file"
}

/usr/sbin/dhclient --version || {
	ldd /usr/sbin/dhclient
	die "/usr/sbin/dhclient not executable"
}
