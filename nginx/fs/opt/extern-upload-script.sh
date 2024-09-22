#!/usr/bin/bash
# NOTE:
# this file is comes from nginx container
# it should at /run/sockets/.nginx.reload.sh
# $0 UUID /path/to/package.tar

declare -r SOCKET="${SHARED_SOCKET_PATH}/.nginx.control.sock"

declare -r CONTAINER_ID=$1 CONFIG_FILE=$2

echo "========================================================"
curl --fail -i --unix-socket "${SOCKET}" \
	--data-binary "@${CONFIG_FILE}" \
	--header "Content-Type: application/x-tar" \
	"http://_/config/${CONTAINER_ID}"
RET=$?
echo "========================================================"

exit ${RET}
