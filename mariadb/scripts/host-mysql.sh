#!/usr/bin/env bash

source "../common/package/include.sh"

use_normal

ID=$(get_container_id)

if [[ -z ${ID} ]]; then
	echo "Container '${ID}' not found."
	exit 1
fi

x podman container exec -it "${ID}" mysql "$@"
