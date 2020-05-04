#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string   PROXY proxy "http proxy url (x.x.x.x:xxx)"
arg_finish "$@"

ENV_PASS=$(
	safe_environment \
		"http_proxy=http://$PROXY" \
		"https_proxy=http://$PROXY"
)

create_pod_service_unit gongt/wordpress
unit_depend $INFRA_DEP mariadb.service
unit_podman_arguments "$ENV_PASS"
unit_fs_bind data/wordpress /data
unit_fs_bind share/nginx /run/nginx
unit_fs_bind share/sockets /run/sockets
unit_fs_bind /data/DevelopmentRoot/github.com/gongt/my-wordpress /project
unit_fs_bind data/wordpress/uploads /project/wp-content/uploads
unit_finish
