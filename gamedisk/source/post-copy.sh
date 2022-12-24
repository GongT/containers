#!/usr/bin/env bash

set -Eeuo pipefail
 
systemctl enable tgtd.service systemd-networkd.service iperf3-server@33233.service
rm -f /etc/tgt/conf.d/sample.conf

rm -f /usr/lib/systemd/network/*

mkdir /etc/systemd/system/systemd-networkd.service.d/
echo -e "[Service]\nEnvironment=SYSTEMD_LOG_LEVEL=debug" > /etc/systemd/system/systemd-networkd.service.d/10-debug.conf 
