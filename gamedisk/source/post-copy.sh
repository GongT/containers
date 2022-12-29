#!/usr/bin/env bash

set -Eeuo pipefail

systemctl enable tgtd.service dhclient.service iperf3-server@33233.service
rm -f /etc/tgt/conf.d/sample.conf
