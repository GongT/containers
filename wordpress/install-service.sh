#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish "$@"

create_pod_service_unit gongt/wordpress
unit_unit After nginx.pod.service mariadb.pod.service
environment_variable \
	"http_proxy=http://$PROXY" \
	"https_proxy=http://$PROXY"
unit_fs_bind data/wordpress /data

shared_sockets_provide word-press
network_use_nat
systemd_slice_type normal
unit_fs_bind /data/DevelopmentRoot/github.com/gongt/my-wordpress /project
unit_fs_bind data/wordpress/uploads /project/wp-content/uploads
unit_finish
