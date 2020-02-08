#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

VOL=$(use_volume virtual-gateway)
if ! [[ -e "$VOL/wg0.conf" ]] ; then
    if ! ssh services.gongt.me echo -e "remote login ok" ; then
        die "Failed SSH login to services.gongt.me, check ssh key files."
    fi
    
    ssh services.gongt.me /usr/bin/env bash < init-script.sh > "$VOL/wg0.conf" ||
    die "Failed to run init script on remote host, check output and try again."
fi

arg_string + DDNS_HOST h/host "ddns host FQDN"
arg_string + DSNS_KEY k/key "ddns api key"
arg_finish "$@"

cat << EOF > /usr/lib/systemd/system/virtual-gateway.service
[Unit]
Description=virtual machine gateway
StartLimitInterval=11
StartLimitBurst=2
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
PIDFile=/run/virtual-gateway.pid
ExecStartPre=-/usr/bin/podman rm --ignore --force virtual-gateway
ExecStart=/usr/bin/podman run --conmon-pidfile=/run/virtual-gateway.pid \\
	--hostname=virtual-gateway --name=virtual-gateway \\
	--network=bridge0 --mac-address=86:13:02:8F:76:2A --dns=none --cap-add=NET_ADMIN \\
	--systemd=false --log-opt=path=/dev/null \\
	--volume=virtual-gateway:/storage \\
	--env="DSNS_KEY=${DSNS_KEY}" --env="DDNS_HOST=${DDNS_HOST}" \\
	--pull=never --rm gongt/infra
RestartPreventExitStatus=125 126 127
ExecStop=-/usr/bin/podman stop -t 10 virtual-gateway
Restart=always
RestartSec=5

[Install]
WantedBy=machines.target

EOF

info "virtual-gateway.service created"

mkdir -p /etc/systemd/system/cockpit.socket.d
echo '[Socket]
ListenStream=/data/AppData/share/sockets/cockpit.sock
ExecStartPost=
ExecStopPost=
' > /etc/systemd/system/cockpit.socket.d/virtual-gateway.conf

systemctl daemon-reload
systemctl enable virtual-gateway.service
