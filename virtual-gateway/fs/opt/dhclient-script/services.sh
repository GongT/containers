#!/usr/bin/env bash

set -Eeuo pipefail

NET_TYPE=$1

function wait_duplicate() {
	echo "wait for DAD"
	while ip -6 addr show | grep ' fe80:' | grep -q tentative; do
		sleep 1
	done
	echo "DAD complete"
}

function do_exit() {
	echo "Receive SIGUSR1, quit dhclient..." >&2
	/usr/sbin/dhclient -v -r -pf "/var/run/dhclient$NET_TYPE.pid"
	wait $PID
}

if [[ $NET_TYPE == 6 ]]; then
	wait_duplicate
fi

trap do_exit USR1

declare -a ENVLINES=() ENVS=()
mapfile -t ENVLINES < <(printenv)
for I in "${ENVLINES[@]}"; do
	ENVS+=(-e "$I")
done

/usr/sbin/dhclient \
	-v \
	"-$NET_TYPE" \
	-d \
	-1 \
	-i \
	-df /storage/dhclient.duid \
	-lf /storage/dhclient.leases \
	-sf "/opt/dhclient-script/entry$NET_TYPE.sh" \
	-pf "/var/run/dhclient$NET_TYPE.pid" \
	"${ENVS[@]}" \
	eth0 &
PID=$!

export PID
wait $PID

echo "wait done... bye bye~"
