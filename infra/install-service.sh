#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + DDNS_HOST h/host "ddns host FQDN"
arg_string + DSNS_KEY k/key "ddns api key"
arg_finish "$@"

VOL=/data/AppData/data/infra
mkdir -p "$VOL"
if ! [[ -e "$VOL/wg0.conf" ]] ; then
    if ! ssh services.gongt.me echo -e "remote login ok" ; then
        die "Failed SSH login to services.gongt.me, check ssh key files."
    fi
    
    ssh services.gongt.me /usr/bin/env bash < init-script.sh > "$VOL/wg0.conf" ||
    die "Failed to run init script on remote host, check output and try again."
fi

STOP_SCRIPT=$(install_script infra-remove-all.sh)

create_pod_service_unit gongt/virtual-gateway
unit_podman_image gongt/infra
unit_unit Description virtual machine gateway
unit_depend network-online.target
unit_body Restart always
unit_hook_stop "-/usr/bin/env bash $STOP_SCRIPT"
unit_hook_start "-/usr/bin/env bash $STOP_SCRIPT"
network_use_manual --network=bridge0 --mac-address=86:13:02:8F:76:2A --dns=none
unit_podman_arguments $(safe_environment \
	"DSNS_KEY=${DSNS_KEY}" \
	"DDNS_HOST=${DDNS_HOST}"
)
unit_fs_bind $VOL /storage
unit_finish

T=$(mktemp)
echo '[Socket]
ListenStream=/data/AppData/share/sockets/cockpit.sock
ExecStartPost=
ExecStopPost=
' > "$T"
env SYSTEMD_EDITOR="cp $T" systemctl edit cockpit.socket

systemctl daemon-reload
systemctl enable virtual-gateway.pod.service
