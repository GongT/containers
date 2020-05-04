#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

create_pod_service_unit gongt/nginx
unit_unit Description qbittorrent
network_use_manual --network=bridge0 --mac-address=86:13:02:8F:76:2A --dns=none
unit_podman_arguments "$ENV_PASS"
unit_start_notify output "start worker process"
unit_body Restart always
unit_fs_bind config/nginx /config
unit_fs_bind logs/nginx /var/log/nginx
unit_fs_tempfs 1M /run
unit_fs_tempfs 512M /tmp
unit_fs_bind share/nginx /config.auto
unit_fs_bind share/letsencrypt /etc/letsencrypt
unit_fs_bind share/sockets /run/sockets
unit_reload_command '/usr/bin/podman exec nginx bash -c "nginx -t && nginx -s reload"'
unit_finish
