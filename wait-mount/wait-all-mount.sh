#!/usr/bin/env bash

mapfile -t UNIT_FILES < <(
	systemctl list-unit-files --type=mount --state=generated \
		--all --no-pager | grep --fixed-strings '.mount' | awk '{print $1}'
)

function expand_timeout() {
	if [[ -n ${NOTIFY_SOCKET} ]]; then
		systemd-notify "EXTEND_TIMEOUT_USEC=$(($1 * 1000000))"
	fi
}

function _notify() {
	echo "$*"
	if [[ -n ${NOTIFY_SOCKET} ]]; then
		systemd-notify --status="$*"
	fi
}

echo "unit files to wait:"
for i in "${UNIT_FILES[@]}"; do
	echo "  * $i"
done

for i in "${UNIT_FILES[@]}"; do
	I=0
	echo "wait $i"
	while ! systemctl is-active -q -- "$i"; do
		expand_timeout 5
		systemctl start --no-block "$i"
		I=$((I + 1))
		_notify "wait $i ($I)"
		if systemctl is-failed -q -- "$i"; then
			_notify "failed wait $i"
			exit 1
		fi
		sleep 1

		if [[ $I -gt 60 ]]; then
			_notify "timeout wait $i"
			exit 1
		fi
	done
	_notify "done $i ($I)"
done

_notify "all mounted"
exit 0
