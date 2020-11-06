#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

export NET_TYPE=6
source ddns-inc.sh

bash /opt/wait-net/wait.sh

mapfile -t CURRENT_IP_OUTPUT < <(ip addr | grep inet6 | grep global | awk '{print $2}' | sed -E 's#/\d+$##g')

pecho "interface ip address:"
for i in "${CURRENT_IP_OUTPUT[@]}"; do
	pecho "  * $i"
done

if [[ ${#CURRENT_IP_OUTPUT[@]} -ne 1 ]]; then
	pecho "failed to detect ip from interface (got ${#CURRENT_IP_OUTPUT[@]} address, but want 1)"
	CURRENT_IP=$(request_url)
else
	CURRENT_IP=${CURRENT_IP_OUTPUT[0]}
fi

if [[ -z $CURRENT_IP ]]; then
	pecho 'failed to get any ip address' >&2
	exit 1
fi

pecho "current ip address is: $CURRENT_IP"

exit_if_same "$CURRENT_IP"

ddns_script

save_current_ip "$CURRENT_IP"
