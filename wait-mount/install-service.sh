#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish "$@"

SCRIPT=$(install_script wait-all-mount.sh)

write_file /usr/lib/systemd/system/wait-mount.service << EOF
[Unit]
Description=wait all mount point before start any pod
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/env bash "$SCRIPT"
Restart=on-failure
NotifyAccess=all
RemainAfterExit=yes
RestartSec=10
StartLimitInterval=90
StartLimitBurst=10

[Install]
WantedBy=multi-user.target

EOF

info "wait-mount.service created"

systemctl daemon-reload
systemctl enable wait-mount.service
