#!/usr/bin/env bash
set -Eeuo pipefail

while read -r LINE; do
	echo "read line: ${LINE}" >&2
	systemctl start --no-block reload-handler-worker.service
done
