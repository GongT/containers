#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

echo "Wait for ip address..."
while [[ -e wait-ip-exists.4.lock ]] || [[ -e wait-ip-exists.6.lock ]]; do
	sleep 3
done
echo "Wait for ip address: Done."
