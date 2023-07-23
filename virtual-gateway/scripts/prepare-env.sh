#!/usr/bin/env bash

set -Eeuo pipefail

systemctl enable systemd-networkd systemd-resolved ddns.timer complete.service
