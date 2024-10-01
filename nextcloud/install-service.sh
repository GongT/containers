#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string + SMTP_PASSWORD smtp_pass "SMTP config (pass)"
arg_finish "$@"

unit_start_notify socket

create_pod_service_unit nextcloud
unit_podman_image registry.gongt.me/gongt/nextcloud
unit_unit After mariadb.pod.service
unit_data danger
environment_variable \
	"PROXY=$PROXY" \
	"SMTP_PASSWORD=$SMTP_PASSWORD"
unit_fs_bind data/nextcloud/apps /var/lib/nextcloud/apps
unit_fs_bind config/nextcloud /usr/share/nextcloud/config
unit_fs_bind logs/nextcloud /var/log/nextcloud
unit_fs_bind /data/NextCloud /data
unit_fs_bind /data/Volumes /drives
shared_sockets_provide next-cloud
# network_use_veth bridge0
systemd_slice_type normal
unit_finish

install_binary scripts/occ.sh occ
