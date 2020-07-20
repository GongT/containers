#!/usr/bin/env bash

set -Eeuo pipefail

IP_CLIENT="10.233.1.2/32"
IP_SERVER="10.233.1.1/32"

RAND_PORT=$(($RANDOM % 30000 + 30000))
PRI_SERVER=$(wg genkey)
PRI_CLIENT=$(wg genkey)

PUB_SERVER=$(echo "$PRI_SERVER" | wg pubkey)
PUB_CLIENT=$(echo "$PRI_CLIENT" | wg pubkey)

PSK=$(wg genpsk)

echo "[NetDev]
Name = wg-gwtun
Kind = wireguard
Description = WireGuard tunnel to virtual gateway at home

[WireGuard]
ListenPort = $RAND_PORT
PrivateKey = $PRI_SERVER

[WireGuardPeer]
# Name = virtual-gateway
PublicKey = $PUB_CLIENT
PresharedKey = $PSK
AllowedIPs = $IP_CLIENT
PersistentKeepalive = 30

" > /etc/systemd/network/82-wg-gwtun.netdev

echo "[Match]
Name = wg-gwtun

[Link]
RequiredForOnline=no
MTUBytes=1420

[Network]
Address = $IP_SERVER

[Route]
Destination = $IP_CLIENT
" > /etc/systemd/network/83-wg-gwtun.network

systemctl restart systemd-networkd

echo "
if wg show \$DEV ; then
	echo 'wireguard interface already exists, skip create.'
else
	ip link add dev \$DEV type wireguard
	ip address add '$IP_CLIENT' dev \$DEV
fi

echo '$PRI_CLIENT' > keyfile
wg set \$DEV listen-port $RAND_PORT private-key keyfile

echo '$PSK' > keyfile
wg set \$DEV peer '$PUB_SERVER' \\
	allowed-ips '$IP_SERVER' \\
	preshared-key keyfile \\
	persistent-keepalive '30' \\
	endpoint 'services.gongt.me:$RAND_PORT'

rm -f keyfile

ip link set up dev \$DEV
ip route replace $IP_SERVER dev \$DEV

"
