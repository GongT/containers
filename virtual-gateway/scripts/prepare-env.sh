#!/usr/bin/env bash

set -Eeuo pipefail

systemctl enable systemd-networkd systemd-resolved ddns.timer complete.service
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
