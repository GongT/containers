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

create_pod_service_unit gongt/mariadb
unit_podman_image gongt/mariadb init
unit_podman_hostname mysql
unit_data danger
unit_podman_arguments "$ENV_PASS"
unit_start_notify output '/usr/bin/mariadbd .+ starting as process '
unit_body OOMScoreAdjust -600
unit_body Environment "TZ=Asia/Shanghai"
unit_body LimitNOFILE 16364

network_use_bridge

# unit_podman_image_pull never
# unit_podman_arguments --privileged
unit_fs_bind logs/mariadb /var/log/mariadb
unit_fs_tempfs 512M /tmp
# unit_body Restart on-failure
unit_body RestartSec 15s
unit_body RestartPreventExitStatus 233
unit_fs_bind data/mariadb /var/lib/mysql
unit_fs_bind /data/backup/mariadb /backup
shared_sockets_provide mariadb php-my-admin
unit_fs_bind share/nginx /run/nginx
unit_finish
