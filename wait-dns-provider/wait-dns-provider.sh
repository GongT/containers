#!/usr/bin/env bash

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

function try() {
	if [[ -z ${NOTIFY_SOCKET} ]]; then
		echo -ne "\e[2m"
	fi
	while true; do
		expand_timeout 32
		if nslookup -timeout=30 "$1" "$2" | grep -A 2 'answer:'; then
			echo "  - success"
			break
		fi
		echo "  - failed"
		sleep 1
	done
	if [[ -z ${NOTIFY_SOCKET} ]]; then
		echo -ne "\e[0m"
	fi
}

# _notify " -> try resolve china dns"
# try z.cn 10.0.0.1

# _notify " -> try resolve world dns"
# try docker.io 10.0.0.1

_notify " -> try resolve china dns (local)"
try z.cn 127.0.0.1

_notify " -> try resolve world dns (local)"
try docker.io 127.0.0.1
