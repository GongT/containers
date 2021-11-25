#!/bin/bash

function x() {
	echo " + $*" >&2
	"$@"
}

if [[ "$UDP2RAW_PASSWORD" ]] ; then
	echo "USE UDP2RAW" >&2
	cat /etc/programs.udp2raw >> /etc/programs
else
	echo "DO NOT USE UDP2RAW" >&2
fi

rm -f /etc/resolv.conf
echo '
nameserver 127.0.0.1
' > /etc/resolv.conf

# set basic network
# x ip addr add 10.100.230.213/24 dev eth0
# x ip route add default via 10.100.230.254
# echo "basic network setup ok." >&2
cat /etc/programs.dhcp >> /etc/programs

exec /sbin/init
