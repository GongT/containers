#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish "$@"

SCRIPT=$(install_script wait-dns-provider.sh)

write_file /usr/lib/systemd/system/wait-dns-provider.service << EOF
[Unit]
Description=wait dns server ready to resolve names
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

info "wait-dns-provider.service created"

systemctl daemon-reload
systemctl enable wait-dns-provider.service
