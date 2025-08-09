#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish "$@"

create_pod_service_unit wordpress
unit_podman_image registry.gongt.me/gongt/wordpress
unit_depend nginx.pod.service mariadb.pod.service

if [[ -n ${PROXY} ]]; then
	environment_variable \
		"http_proxy=http://${PROXY}" \
		"https_proxy=http://${PROXY}"
fi

shared_sockets_provide word-press
network_use_veth
systemd_slice_type normal

unit_fs_bind data/wordpress /data
unit_fs_bind /data/DevelopmentRoot/github.com/gongt/my-wordpress /project
unit_fs_bind data/wordpress/uploads /project/wp-content/uploads

unit_finish
