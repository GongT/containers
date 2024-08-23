#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string PROXY proxy "http proxy url (x.x.x.x:xxx)"
arg_finish "$@"

create_pod_service_unit gongt/mariadb
unit_podman_image gongt/mariadb init
unit_podman_hostname mysql
unit_data danger

# unit_start_notify output '/usr/bin/mariadbd .+ starting as process '
unit_body OOMScoreAdjust -600
unit_body Environment "TZ=Asia/Shanghai"
unit_body LimitNOFILE 16364

unit_using_systemd
network_use_nat
systemd_slice_type infrastructure

# unit_podman_image_pull never
# unit_podman_arguments --privileged
unit_fs_bind logs/mariadb /var/log/mariadb
unit_fs_tempfs 512M /tmp
# unit_body Restart on-failure
unit_body RestartSec 15s
unit_body RestartPreventExitStatus 233
unit_fs_bind data/mariadb /var/lib/mysql
unit_fs_bind /data/Backup/mariadb /backup
shared_sockets_provide mariadb php-my-admin
unit_fs_bind share/nginx /run/nginx

unit_podman_safe_environment "PROXY=$PROXY"

unit_finish
