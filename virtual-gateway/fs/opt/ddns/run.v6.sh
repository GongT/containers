#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

export NET_TYPE=6
source ddns-inc.sh

mapfile -t CURRENT_IP_OUTPUT < <(ip addr | grep inet6 | grep global | grep -v deprecated | awk '{print $2}' | sed -E 's#/[0-9]+$##g' | sort -u -)

pecho "interface ip address:"
for i in "${CURRENT_IP_OUTPUT[@]}"; do
	pecho "  * $i"
done

exit_if_same_list "${CURRENT_IP_OUTPUT[@]}"

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

exit_if_same "$CURRENT_IP"

pecho "current ip address is: $CURRENT_IP"

ddns_script "$NET_TYPE" "$CURRENT_IP"

save_current_ip "${CURRENT_IP}"
save_current_ip_list "${CURRENT_IP_OUTPUT[@]}"
