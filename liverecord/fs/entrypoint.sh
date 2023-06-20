#!/usr/bin/env bash

set -Eeuo pipefail

source /opt/create-config.sh

if [[ $# -eq 0 ]]; then
	exec /usr/sbin/init "$@"
else
	exec "$@"
fi
