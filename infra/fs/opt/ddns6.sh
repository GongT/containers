#!/bin/bash

set -Eeuo pipefail

export NET_TYPE=6
source /opt/_inc.sh

SAVE_FILE=/storage/save.ip.out
SAVE_IP_FILE=/storage/save.ip
CURRENT_IP_OUTPUT=$(ip addr | grep inet6 | grep global | awk '{print $2}' | sed -E 's#/\d+$##g')
CURRENT_IP_LIST=($CURRENT_IP_OUTPUT)

pecho "current ip address:"
for i in $CURRENT_IP_OUTPUT; do
	pecho "  * $i"
done

if [[ -e "$SAVE_FILE" ]]; then
	if [[ "$(<$SAVE_FILE)" == "$CURRENT_IP_OUTPUT" ]]; then
		pecho "current IP output not change"
		exit 0
	else
		pecho "    saved IP output has change. saved was:"
		for i in $(<$SAVE_FILE); do
			pecho "      * $i"
		done
	fi
else
	pecho "    no saved IP output."
fi

bash /opt/wait-net.sh

CNT=$(echo "$CURRENT_IP_OUTPUT" | wc -l)
if [[ "$CNT" -ne 1 ]]; then
	pecho "failed to detect ip from interface (got $CNT address, but want 1 only)"
	CURRENT_IP=$(request_url)
else
	pecho "use it"
	CURRENT_IP=$CURRENT_IP_OUTPUT
fi

if [[ -z "$CURRENT_IP" ]]; then
	pecho 'failed to get any ip address' >&2
	exit 1
fi

pecho "current ip address is: $CURRENT_IP"

if [[ -e "$SAVE_IP_FILE" ]]; then
	if [[ "$(<$SAVE_IP_FILE)" == "$CURRENT_IP" ]]; then
		pecho "current IP not change ($CURRENT_IP)."
		echo -n "$CURRENT_IP_OUTPUT" >"$SAVE_FILE"
		exit 0
	else
		pecho "    saved was: $(<$SAVE_IP_FILE)"
	fi
else
	pecho "    no saved IP."
fi

ddns_script

echo -n "$CURRENT_IP_OUTPUT" >"$SAVE_FILE"
echo -n "$CURRENT_IP" >"$SAVE_IP_FILE"
pecho "state saved."
