#!/bin/bash

set -Eeuo pipefail

ip addr

exec udhcpc -i eth0 -n -R -f -x hostname:shabao-proxy-server # -r 10.100.230.213
