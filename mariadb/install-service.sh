#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string   PROXY proxy "http proxy url (x.x.x.x:xxx)"
arg_finish "$@"

ENV_PASS=$(
	safe_environment \
		"PROXY=$PROXY"
)

cat << EOF > /usr/lib/systemd/system/mariadb.service
[Unit]
Description=mysql server
StartLimitInterval=11
StartLimitBurst=2
After=network-online.target $INFRA_DEP
Requires=$INFRA_DEP
Wants=network-online.target

[Service]
OOMScoreAdjust=-600
Environment="TZ=Asia/Shanghai"
LimitNOFILE=16364
Type=simple
PIDFile=/run/mariadb.pid
ExecStartPre=-/usr/bin/podman stop -t 120 mariadb
ExecStartPre=-/usr/bin/podman rm --ignore --force mariadb
ExecStart=/usr/bin/podman run --conmon-pidfile=/run/mariadb.pid \\
	--hostname=mysql --name=mariadb \\
	$NETWORK_TYPE $ENV_PASS \\
	--systemd=false --log-opt=path=/dev/null \\
	--mount=type=bind,src=/data/AppData/logs/mariadb,dst=/var/log/mariadb \\
	--mount=type=tmpfs,tmpfs-size=512M,destination=/run \\
	--volume=backup-mysql:/backup \\
	--volume=mariadb:/var/lib/mysql \\
	--volume=sockets:/run/sockets \\
	--pull=never --rm gongt/mariadb
RestartPreventExitStatus=125 126 127
ExecStop=-/usr/bin/podman stop -t 120 mariadb
Restart=always
RestartSec=5

[Install]
WantedBy=machines.target
EOF


info "mariadb.service created"

systemctl daemon-reload
systemctl enable mariadb.service
