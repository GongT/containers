#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

create_unit wordpress
unit_depend $INFRA_DEP mariadb.service
unit_fs_bind data/wordpress /data
unit_fs_bind share/nginx /run/nginx
unit_fs_bind share/sockets /run/sockets
unit_fs_bind /data/DevelopmentRoot/github.com/gongt/my-wordpress /project
unit_finish
