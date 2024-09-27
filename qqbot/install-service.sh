#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

arg_finish

auto_create_pod_service_unit
unit_podman_image registry.gongt.me/gongt/qqbot
unit_unit Description Mirai QQ bot server
# unit_podman_image_pull never

podman_engine_params -it

unit_body Restart no
unit_start_notify output "Login successful"

network_use_nat 56080:80/tcp # this for debug only
systemd_slice_type normal

unit_fs_bind config/qqbot /mirai/config
unit_fs_bind data/qqbot/data /mirai/data
unit_fs_bind data/qqbot/bots /mirai/bots
unit_fs_bind logs/qqbot /mirai/logs

unit_finish
