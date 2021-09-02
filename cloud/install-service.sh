#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string   PROXY               proxy                 "http proxy url (x.x.x.x:xxx)"
arg_string + SMTP_PASSWORD       smtp_pass             "SMTP config (pass)"
arg_finish "$@"

ENV_PASS=$(safe_environment \
	"PROXY=$PROXY" \
	"SMTP_PASSWORD=$SMTP_PASSWORD"
)

create_pod_service_unit gongt/cloud
unit_unit Requires mariadb.pod.service
unit_data danger
unit_podman_arguments "$ENV_PASS"

unit_fs_bind data/cloud/apps /var/lib/nextcloud/apps
unit_fs_bind config/cloud /usr/share/webapps/nextcloud/config
unit_fs_bind logs/cloud /var/log/nextcloud
unit_fs_bind /data/Volumes/AppData/NextCloud /data
unit_fs_bind /data/Volumes /drives
shared_sockets_provide next-cloud
network_use_nat
systemd_slice_type normal
unit_finish

install_binary scripts/occ.sh
