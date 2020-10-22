#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

declare -rx NET_TYPE=6
source dhclient-inc6.sh
source dhclient-inc.sh

# lease=4294967295
# ipv6=fd63:f3f5:016e:0010:0000:0000:0000:0ce1
# dns=fd63:f3f5:016e:0010:0000:0000:0000:0001
# interface=eth0
