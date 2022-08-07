#!/usr/bin/env bash

set -Eeuo pipefail

mkdir -p /mountpoints /drives

if ! grep -q -- smbusers /etc/group; then
	groupadd smbusers
fi

if ! grep -q -- media_rw /etc/passwd; then
	useradd --groups users,root --uid 100 --gid 100 --no-user-group --no-create-home media_rw
fi

systemctl enable smb nmb prepare systemd-networkd always-online.timer
systemctl disable systemd-networkd-wait-online.service
