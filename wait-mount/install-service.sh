#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

install_script wait-all-mount.sh SCRIPT

cat << EOF > /usr/lib/systemd/system/wait-mount.service
[Unit]
Description=wait all mount point before start any pod
After=network-online.target
Before=virtual-gateway.pod.service

[Service]
Type=oneshot
ExecStart=/usr/bin/env bash "$SCRIPT"
Restart=no
NotifyAccess=all
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target

EOF

info "wait-mount.service created"

systemctl daemon-reload
systemctl enable wait-mount.service
