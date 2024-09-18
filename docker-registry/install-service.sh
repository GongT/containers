#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

create_pod_service_unit gongt/docker-registry
unit_unit Description personal docker image registry
unit_unit Documentation https://docs.docker.com/registry/configuration/

shared_sockets_provide docker-registry
network_use_nat
unit_unit After nginx.pod.service
systemd_slice_type normal
# unit_podman_image_pull never
unit_fs_bind data/docker-registry /var/lib/registry
unit_finish
