#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string   PROXY               proxy                 "http proxy url (x.x.x.x:xxx)"
arg_string + SMTP_PASSWORD       smtp_pass             "SMTP config (pass)"
arg_finish "$@"

ENV_PASS=$(
	safe_environment \
		"PROXY=$PROXY" \
		"SMTP_PASSWORD=$SMTP_PASSWORD"
)

cat << EOF > /usr/lib/systemd/system/cloud.service
[Unit]
Description=NextCloud server
StartLimitInterval=11
StartLimitBurst=2
After=network-online.target $INFRA_DEP mariadb.service
Requires=$INFRA_DEP mariadb.service
Wants=network-online.target

[Service]
Type=simple
PIDFile=/run/cloud.pid
ExecStartPre=-/usr/bin/podman rm --ignore --force cloud
ExecStart=/usr/bin/podman run --conmon-pidfile=/run/cloud.pid \\
	--hostname=cloud --name=cloud \\
	$NETWORK_TYPE $ENV_PASS \\
	--systemd=false --log-opt=path=/dev/null \\
	$(bind /data/AppData/data/cloud/apps /var/lib/nextcloud/apps) \\
	$(bind /data/AppData/config/cloud /usr/share/webapps/nextcloud/config) \\
	$(bind /data/AppData/logs/cloud /var/log/nextcloud) \\
	$(bind /data/Volumes/AppData/NextCloud /data) \\
	$(bind volumes /drives) \\
	--volume=sockets:/run/sockets \\
	--pull=never --rm gongt/cloud
RestartPreventExitStatus=125 126 127
ExecStop=-/usr/bin/podman stop -t 20 cloud
Restart=always
RestartSec=5

[Install]
WantedBy=machines.target
EOF

echo '#!/bin/sh

podman exec -it cloud /usr/bin/occ "$@"
' > /usr/local/bin/occ
chmod a+x  /usr/local/bin/occ

info "cloud.service created"

systemctl daemon-reload
systemctl enable cloud.service
