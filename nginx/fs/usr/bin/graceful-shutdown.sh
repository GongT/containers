#!/bin/sh

PID=$(systemctl show nginx --property=MainPID --value)
if [[ -z ${PID} ]]; then
	echo "no main pid exists" >&2
	exit 0
fi
if ! kill -s 0 "${PID}"; then
	echo "process died" >&2
	exit 0
fi

kill -s SIGQUIT "${PID}" || {
	echo "failed kill" >&2
	exit 1
}

while [ -d "/proc/$PID" ]; do
	sleep 1 &
	wait $!
done

exit 0
