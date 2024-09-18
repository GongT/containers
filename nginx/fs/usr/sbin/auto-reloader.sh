#!/usr/bin/env bash
set -Eeuo pipefail

declare -r MARKFILE='/run/nginx/please-reload'

while sleep 5; do
	if [[ -e "${MARKFILE}" ]]; then
		echo " --> found reload mark (${MARKFILE})"
		rm -f "${MARKFILE}"
		bash /usr/bin/safe-reload
	fi
done
