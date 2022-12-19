#!/usr/bin/env bash

set -Eeuo pipefail

NET_TYPE=$1
interface=eth0

function wait_duplicate() {
	echo "wait for DAD"
	while ip -6 addr show | grep ' fe80:' | grep -q tentative; do
		sleep 1
	done
	echo "DAD complete"
}

function do_exit() {
	echo "Receive SIGUSR1, quit dhclient..." >&2
	/usr/sbin/dhclient \
		-v \
		-r \
		"${CONFIG_ARGS[@]}" \
		"$interface"
}

if [[ $NET_TYPE == 6 ]]; then
	wait_duplicate
else
	trap do_exit USR1
fi

declare -a ENVLINES=() ENVS=()
mapfile -t ENVLINES < <(printenv)
for I in "${ENVLINES[@]}"; do
	ENVS+=(-e "$I")
done

declare -a CONFIG_ARGS=(
	-cf /etc/dhclient.conf
	-df /storage/dhclient.duid
	-lf /storage/dhclient.leases
	-sf "/opt/dhclient-script/entry$NET_TYPE.sh"
	-pf "/var/run/dhclient$NET_TYPE.pid"
)

declare -i RETRY=0
while true; do
	/usr/sbin/dhclient \
		-v \
		"-$NET_TYPE" \
		-d \
		-1 \
		-i \
		"${CONFIG_ARGS[@]}" \
		"${ENVS[@]}" \
		"$interface" &
	PID=$!

	export PID
	echo "PID=$PID"

	set +Ee
	wait $PID
	RET=$?

	echo -n "wait done (code $RET)..."

	# 2 is not got ip
	if [[ $RET -eq 2 ]] && [[ $RETRY -lt 5 ]]; then
		RETRY="$RETRY + 1"
		echo "retry ($RETRY) in 5s..."
		sleep 5
		continue
	fi

	echo "bye bye~"

	if [[ $NET_TYPE == 6 ]]; then
		echo "halt~ (disable ipv6)"
		bash /opt/wait-net/delete.sh "$NET_TYPE"
		sleep infinity
	else
		echo "bye bye~"
		exit $RET
	fi
done
