#!/bin/sh

source "../common/package/include.sh"

CID="$(get_container_id)"
set -x
exec podman exec --user media_rw:users \
	--workdir=/usr/share/nextcloud \
	-it "${CID}" \
	/usr/bin/php -d memory_limit=2G occ "$@"
