#!/usr/bin/env bash

set -Eeuo pipefail

if [[ $# -eq 0 ]]; then
	exec /usr/sbin/init "$@"
else
	exec "$@"
fi
