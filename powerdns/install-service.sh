#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_string _PUBPORT p/port "public port of this server (defaults to 53)"
arg_finish "$@"

PUBPORT=${_PUBPORT:-53}

create_pod_service_unit gongt/powerdns
unit_podman_hostname homedns
unit_unit Description home dns server
unit_fs_tempfs 1M /run
unit_fs_tempfs 50M /tmp
shared_sockets_provide powerdns
unit_fs_bind data/powerdns /data
unit_finish
