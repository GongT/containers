#!/bin/bash

set -Eeuo pipefail

export NET_TYPE=4
source /opt/_inc.sh

SAVE_FILE=/storage/save.ip.4

bash /opt/wait-net.sh

if [[ -e "$SAVE_FILE" ]]; then
	LAST_IP=$(<"$SAVE_FILE")
else
	LAST_IP=""
fi
pecho "current ip address is: $LAST_IP"

CURRENT_IP=$(request_url)
pecho "get my real ip address is: $CURRENT_IP"

if [[ "$LAST_IP" == "$CURRENT_IP" ]]; then
	pecho " * same, do nothing"
	exit 0
fi

ddns_script

echo -n "$CURRENT_IP" >"$SAVE_FILE"
pecho "state saved."
