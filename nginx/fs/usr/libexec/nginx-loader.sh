#!/usr/bin/bash

set -Eeuo pipefail

function __prepare() {
	echo "locked in process: $$"

	mkdir -p /etc/ACME/nginx

	link-effective main
	config-file-macro /etc/nginx

	## todo: dynamic parsed
	rm -f "${SHARED_SOCKET_PATH}/http.sock" "${SHARED_SOCKET_PATH}/http.sock" "${SHARED_SOCKET_PATH}/reload.sock"

	/usr/sbin/nginx -t || {
		echo "===================================="
		echo "!! Failed test nginx config files !!"
		echo "===================================="
		exit 127
	}
}

export -f __prepare
lock-config __prepare
unset __prepare

echo "start /usr/sbin/nginx"
exec /usr/sbin/nginx
