#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

F="wait-ip-exists.$1.lock"

if [[ -e $F ]]; then
	echo "[wait] delete file: $F"
	rm "$F"

	if [[ ! -e wait-ip-exists.4.lock ]] && [[ ! -e wait-ip-exists.6.lock ]]; then
		echo "~~~ network startup complete ~~~"
	fi
fi
