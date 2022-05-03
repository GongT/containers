#!/usr/bin/env bash

set -Eeuo pipefail

PID=$(</tmp/resilio.pid)

echo "killing process $PID"
kill -s SIGINT "$PID" || true

declare -i I=0
while ls -l "/proc/$PID/exe"; do
	sleep 1
	I="$I + 1"

	if [[ $I -gt 5 ]]; then
		echo "[$I] waitting process to quit..."
	fi
	if [[ $I -gt 10 ]]; then
		echo "         kill $PID"
		kill -s SIGINT "$PID" || true
	fi
done

rm -f /tmp/resilio.pid
echo "process has exited"
