#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

create_pod_service_unit gongt/docker-registry
unit_unit Description personal docker image registry
unit_unit Documentation https://docs.docker.com/registry/configuration/
unit_fs_bind share/nginx /run/nginx
shared_sockets_provide docker-registry
unit_fs_bind data/docker-registry /var/lib/registry
unit_podman_arguments --env="REGISTRY_HTTP_ADDR=/run/sockets/docker-registry.sock" \
	 --env="REGISTRY_HTTP_NET=unix"
unit_finish
