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

create_unit gongt/mariadb
unit_podman_hostname mysql
unit_data danger
unit_podman_arguments "$ENV_PASS"

unit_body OOMScoreAdjust -600
unit_body Environment "TZ=Asia/Shanghai"
unit_body LimitNOFILE 16364

unit_podman_arguments --privileged
unit_fs_bind logs/mariadb /var/log/mariadb
unit_fs_tempfs 512M /tmp
unit_fs_bind data/mariadb /var/lib/mysql
unit_fs_bind backup/mariadb /backup
unit_fs_bind share/sockets /run/sockets
unit_finish
