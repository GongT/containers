#!/usr/bin/bash
# NOTE:
# this file is comes from nginx container
# it should at /run/sockets/.nginx.reload.sh
# $0 UUID /path/to/package.tar

declare -r SOCKET="${SHARED_SOCKET_PATH}/.nginx.control.sock"

declare -r CONTAINER_ID=$1 CONFIG_FILE=$2

echo "========================================================"
if [[ ${CONFIG_FILE} == '-' ]]; then
	echo "deleting..."
	curl -s --fail-with-body -i --unix-socket "${SOCKET}" \
		"http://_/delete/${CONTAINER_ID}"
else
	echo "uploading..."
	curl -s --fail-with-body -i --unix-socket "${SOCKET}" \
		--data-binary "@${CONFIG_FILE}" \
		--header "Content-Type: application/x-tar" \
		"http://_/config/${CONTAINER_ID}"
	RET=$?
fi
echo "========================================================"

exit ${RET}
