#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

declare -rx NET_TYPE=6
source dhclient-inc6.sh
source dhclient-inc.sh

# new_dhcp6_solmax_rt=60
# new_max_life=254001
# pid=63
# new_dhcp6_name_servers=fd00:db80:2333::6666:1 fd00:db80:2333::6666:1
# new_ip6_prefixlen=128
# new_life_starts=1604682414
# new_iaid=02:8f:76:2a
# new_preferred_life=167601
# new_rebind=34560
# new_starts=1604682414
# dad_wait_time=0
# new_dhcp6_server_id=0:3:0:1:e4:3a:6e:2b:79:b4
# requested_dhcp6_domain_search=1
# interface=eth0
# new_dhcp6_client_id=0:1:0:1:27:38:3f:2c:86:13:2:8f:76:2a
# new_ip6_address=2408:8207:78aa:9d40::95c
# requested_dhcp6_name_servers=1
# reason=BOUND6
# new_renew=21600
