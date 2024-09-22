#!/usr/bin/bash

set -Eeuo pipefail

mkdir -p /etc/ACME/nginx

erun() {
	echo " + $*" >&2
	"$@"
}

config-file-macro /etc/nginx

## todo: dynamic parsed
rm -f "${SHARED_SOCKET_PATH}/http.sock" "${SHARED_SOCKET_PATH}/http.sock" "${SHARED_SOCKET_PATH}/reload.sock"

/usr/sbin/nginx -t || {
	echo "===================================="
	echo "!! Failed test nginx config files !!"
	echo "===================================="
	exit 127
}

exec /usr/sbin/nginx
