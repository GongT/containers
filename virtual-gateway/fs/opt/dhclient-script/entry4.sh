#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

declare -rx NET_TYPE=4
source dhclient-inc4.sh
source dhclient-inc.sh

# lease=43200
# mask=16
# ip=10.0.1.26
# broadcast=10.0.255.255
# router=10.0.0.1
# siaddr=10.0.0.1
# domain=local
# dns=10.0.0.1
# hostname=virtual-gateway
# serverid=10.0.0.1
# subnet=255.255.0.0
# opt59=000093a8
# opt58=00005460
# opt53=05
# interface=eth0
