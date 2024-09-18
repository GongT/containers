#!/bin/sh

source "../common/package/include.sh"

use_normal

exec podman exec -it "$(get_container_id)" /usr/bin/occ "$@"
