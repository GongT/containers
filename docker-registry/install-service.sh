#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

cat << EOF > /usr/lib/systemd/system/docker-registry.service
[Unit]
Description=personal docker image registry
Documentation=https://docs.docker.com/registry/configuration/
StartLimitInterval=11
StartLimitBurst=2
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
PIDFile=/run/docker-registry.pid
ExecStart=/usr/bin/podman run --conmon-pidfile=/run/docker-registry.pid \\
	--hostname=docker-registry --name=docker-registry \\
	$NETWORK_TYPE \\
	--systemd=false --log-opt=path=/dev/null \\
	--volume=docker-registry-store:/var/lib/registry \\
	--env="REGISTRY_HTTP_HOST=http://docker-registry.services.gongt.me" \\
	--rm registry
RestartPreventExitStatus=125 126 127
ExecStop=/usr/bin/podman stop --ignore -t 10 docker-registry
Restart=always
RestartSec=5

[Install]
WantedBy=machines.target

EOF

info "docker-registry.service created"

systemctl daemon-reload
systemctl enable docker-registry.service
