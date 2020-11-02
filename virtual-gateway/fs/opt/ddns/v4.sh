#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

export NET_TYPE=4
source ddns-inc.sh

bash /opt/wait-net/wait.sh

CURRENT_IP=$(request_url)

pecho "current ip address:"
pecho "  * $CURRENT_IP"

if [[ -z $CURRENT_IP ]]; then
	pecho 'failed to get any ip address' >&2
	exit 1
fi

exit_if_same "$CURRENT_IP"

ddns_script

save_current_ip "$CURRENT_IP"
