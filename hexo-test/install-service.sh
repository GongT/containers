#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

create_pod_service_unit gongt/hexo
unit_fs_bind data/hexo/source /data/source
unit_fs_bind data/hexo/images /data/images
unit_fs_bind share/nginx /run/nginx
shared_sockets_use
unit_fs_bind config/hexo /etc/hexo
unit_finish
