#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

cat << EOF > /usr/lib/systemd/system/powerdns.service
[Unit]
Description=home dns server
Documentation=http://nginx.org/en/docs/
StartLimitInterval=11
StartLimitBurst=2
Wants=php-fpm.service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
PIDFile=/run/powerdns.pid
ExecStart=/usr/bin/podman run --conmon-pidfile=/run/powerdns.pid \\
	--hostname=homedns --name=powerdns \\
	-p 53:53 -p 53:53/udp -p 127.0.0.1:53000:53000 \\
	--net=my \\
	--systemd=false --log-opt=path=/dev/null \\
	--mount=type=bind,ro,src=/data/AppData/config/nginx,dst=/config \\
	--mount=type=tmpfs,tmpfs-size=1M,destination=/run \\
	--mount=type=tmpfs,tmpfs-size=512M,destination=/tmp \\
	--volume=wellknown:/etc/wellknown \\
	--volume=sockets:/var/run/sockets \\
	--mount=type=bind,src=/data/AppData/data/powerdns,dst=/data \\
	--pull=never --rm gongt/powerdns
RestartPreventExitStatus=125 126 127
ExecStop=/usr/bin/podman stop --ignore -t 10 powerdns
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target

EOF

info "powerdns.service created"

systemctl daemon-reload
