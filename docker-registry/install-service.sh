#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-install.sh

create_unit docker-registry
unit_podman_image registry
unit_unit Description personal docker image registry
unit_unit Documentation https://docs.docker.com/registry/configuration/
unit_depend $INFRA_DEP
unit_fs_bind /data/AppData/data/docker-registry /var/lib/registry
unit_podman_arguments --env="REGISTRY_HTTP_HOST=http://docker-registry.services.gongt.me"
unit_finish
