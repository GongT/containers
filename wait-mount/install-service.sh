#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

mkdir -p /usr/share/scripts
cp wait-all-mount.sh /usr/share/scripts/wait-all-mount.sh

cat << EOF > /usr/lib/systemd/system/wait-mount.service
[Unit]
Description=wait all mount point before start any pod
After=network-online.target
Before=virtual-gateway.service

[Service]
Type=oneshot
ExecStart=/usr/bin/env bash "/usr/share/scripts/wait-all-mount.sh"
Restart=no
NotifyAccess=all

[Install]
WantedBy=machines.target

EOF

info "wait-mount.service created"

systemctl daemon-reload
systemctl enable wait-mount.service
