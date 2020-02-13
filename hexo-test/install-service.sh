#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

create_unit hexo
unit_podman_image gongt/hexo
unit_depend $INFRA_DEP mariadb.service
unit_fs_bind data/hexo/source /data/source
unit_fs_bind data/hexo/images /data/images
unit_fs_bind share/nginx /run/nginx
unit_fs_bind share/sockets /run/sockets
unit_fs_bind config/hexo /etc/hexo
unit_finish
