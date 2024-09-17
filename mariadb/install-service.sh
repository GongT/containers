#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish "$@"

create_pod_service_unit gongt/mariadb
unit_podman_image registry.gongt.me/gongt/mariadb
unit_podman_hostname mysql
unit_data danger

unit_start_notify socket

unit_body OOMScoreAdjust -600
unit_body Environment "TZ=Asia/Shanghai"
unit_body LimitNOFILE 16364

systemd_slice_type infrastructure
# unit_podman_image_pull never
unit_body Restart on-failure
unit_body RestartSec 30s

unit_fs_tempfs 512M /tmp
unit_fs_bind logs/mariadb /var/log/mariadb
unit_fs_bind data/mariadb /var/lib/mysql
unit_fs_bind /data/Backup/mariadb /backup
unit_fs_bind share/nginx /run/nginx

network_use_auto 33306/tcp
shared_sockets_provide mariadb php-my-admin

unit_podman_safe_environment "PROXY=${PROXY-}"

unit_finish

install_binary "$(realpath "scripts/host-mysql.sh")" "mysql"
