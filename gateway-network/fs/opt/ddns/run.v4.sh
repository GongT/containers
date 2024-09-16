#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

export NET_TYPE=4
source ddns-inc.sh

CURRENT_IP=$(request_url)

if [[ -z $CURRENT_IP ]]; then
	pecho 'failed to get any ip address' >&2
	exit 1
fi

pecho "current ip address:"
pecho "  * $CURRENT_IP"

exit_if_same "$CURRENT_IP"

ddns_script "$NET_TYPE" "$CURRENT_IP"

save_current_ip "$CURRENT_IP"
