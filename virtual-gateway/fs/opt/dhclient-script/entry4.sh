#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

declare -rx NET_TYPE=4
source dhclient-inc4.sh
source dhclient-inc.sh

# new_domain_name=local
# new_network_number=10.0.0.0
# new_routers=10.0.0.1
# new_domain_name_servers=10.0.0.1
# new_dhcp_server_identifier=10.0.0.1
# pid=68
# new_dhcp_lease_time=43200
# new_dhcp_message_type=5
# new_expiry=1604728451
# new_broadcast_address=10.0.255.255
# new_dhcp_rebinding_time=37800
# requested_domain_name=1
# requested_subnet_mask=1
# requested_time_offset=1
# new_ip_address=10.0.0.170
# requested_routers=1
# dad_wait_time=0
# requested_broadcast_address=1
# new_dhcp_renewal_time=21600
# requested_domain_name_servers=1
# interface=eth0
# new_next_server=10.0.0.1
# reason=BOUND
# new_subnet_mask=255.255.0.0
# requested_host_name=1
