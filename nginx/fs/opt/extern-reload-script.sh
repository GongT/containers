#!/usr/bin/bash
# NOTE:
# this file is comes from nginx container
# it should at /run/sockets/.nginx.reload.sh

declare -r SOCKET="${SHARED_SOCKET_PATH}/.nginx.control.sock"
if ! [[ -e ${SOCKET} ]]; then
	echo "nginx controller socket not found, maybe it's not running."
	exit 0
fi

declare -i RET=0
if command -v curl &>/dev/null; then
	echo "notify nginx to reload."
	echo '======================================' >&2
	curl --fail-with-body -i --unix-socket "${SOCKET}" http://_/reload
	RET=$?
	echo '======================================' >&2
else
	echo "missing supported communication tool."
fi
exit ${RET}
