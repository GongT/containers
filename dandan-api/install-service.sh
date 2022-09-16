#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_flag PROXY proxy "代理服务器地址"
arg_finish "$@"

create_pod_service_unit dandan-api
unit_podman_image_pull never
unit_podman_image gongt/dandan-api
unit_unit Description "dandan-api - dmhy proxy server for dandanplay"
unit_unit Documentation "https://github.com/kaedei/dandanplay-libraryindex/blob/master/api/ResourceService.md"
network_use_auto
systemd_slice_type normal
environment_variable "PROXY=$PROXY"
unit_start_notify sleep "5"
shared_sockets_provide dandan-api

unit_finish
