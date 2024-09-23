#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit extglob nullglob globstar lastpipe shift_verbose

WHAT=$1

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
cd ..

if [[ -z ${WHAT} ]]; then
	echo 'Usage: $0 <container id>'
	exit 1
fi
CONTAINER_ID=$(podman container list '--format={{.Names}}' | grep "${WHAT}" | head -n1)
if [[ -z ${CONTAINER_ID} ]]; then
	echo "no container have ${WHAT} in name"
	exit 1
fi

SERVICE_NAME=$(podman container inspect '--format={{index .Config.Annotations "systemd.unit.name"}}' "${CONTAINER_ID}")
if [[ -z ${SERVICE_NAME} ]]; then
	echo 'service (container) not found.'
	exit 1
fi

OUT=$(systemctl cat "${SERVICE_NAME}" | grep -E '^CURRENT_DIR=')
if [[ -z ${SERVICE_NAME} ]]; then
	echo 'service file is invalid.'
	exit 1
fi

declare -r "${OUT}"

if [[ ! -d "${CURRENT_DIR}/fs" ]]; then
	echo "required filesystem not exists: ${CURRENT_DIR}/fs"
	exit 1
fi

TGT=$(podman container mount "${CONTAINER_ID}")

if [[ ! -d ${TGT} ]]; then
	echo "???? ${TGT}"
	exit 1
fi
echo "copy filesystem:"
echo "    from: ${CURRENT_DIR}/fs"
echo "    to:   ${TGT}"

rsync --itemize-changes --archive --checksum "${CURRENT_DIR}/fs/." "${TGT}"
