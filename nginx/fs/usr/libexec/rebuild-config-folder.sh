#!/usr/bin/bash
set -Euo pipefail
shopt -s extglob nullglob globstar shift_verbose

# CONFIG_ROOT = /run/nginx/config
# STORE_ROOT = /run/nginx/contributed
# TESTING_DIR = /tmp/testing

echo "will rebuild config dir"

function empty_dir() {
	local DIR=$1
	if [[ ! -d ${DIR} ]]; then
		mkdir -p "${DIR}"
		return
	fi
	find "${DIR}" -mindepth 1 -maxdepth 1 -exec rm -rf '{}' \;
}

# todo: detect change

empty_dir "${CONFIG_ROOT}"

find "${STORE_ROOT}" -name '*.tar' -print0 | while read -d '' -r FILE; do
	echo "  - ${FILE}"
	tar -xf "${FILE}" -C "${CONFIG_ROOT}"
done

link-effective main
config-file-macro /etc/nginx
nginx -t && nginx -s reload
