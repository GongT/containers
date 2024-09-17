#!/usr/bin/env bash

source "../common/package/include.sh"

CONTAINER_ID=$(get_container_id)

x podman container exec -it "${CONTAINER_ID}" mysql "$@"
