#!/usr/bin/env bash

set -Eeuo pipefail

echo '['
SIGFOUND=
while IFS= read -r line; do
	TITLE_LINK=$(echo "$line" | awk -F ' *\\| *' '{print $2}' | sed -E 's#^.*\[(.+)].*$#\1#g')

	if [[ $TITLE_LINK =~ ^-+$ ]]; then
		SIGFOUND=yes
		continue
	elif [[ ! $SIGFOUND ]]; then
		continue
	fi

	TITLE_SECRET=$(echo "$line" | awk -F ' *\\| *' '{print $5}' | sed -E 's#[^0-9a-zA-Z]##g')
	if [[ $(echo -n "$TITLE_SECRET" | wc -c) -ne 33 ]]; then
		echo "===================================" >&2
		echo "Invalid Line: hash not equals to 33" >&2
		echo "$line" >&2
		echo "===================================" >&2
	fi

	TITLE_ESCAPE=$(echo "${TITLE_LINK}" | sed 's#[\\\/:*?"<>|]##g')
	LINK_FILE="${MENU_DIR}/${TITLE_ESCAPE}"

	echo "[${TITLE_SECRET}] ${TITLE_LINK}" >&2
	if [[ -L "${LINK_FILE}" ]] && [[ $(readlink "${LINK_FILE}") == "../${TITLE_SECRET}" ]]; then
		:
	else
		unlink "${LINK_FILE}" 2>/dev/null || true
		ln -s "../$TITLE_SECRET" "${LINK_FILE}"
	fi

	printf "{\n"
	printf '\t"dir": "%s",\n' "/data/content/$TITLE_SECRET"
	printf '\t"use_relay_server": false,\n'
	printf '\t"use_tracker": true,\n'
	printf '\t"search_lan": true,\n'
	printf '\t"use_sync_trash": false,\n'
	printf '\t"overwrite_changes": true,\n'
	printf '\t"selective_sync": false,\n'
	printf '\t"secret": "%s"\n' "$TITLE_SECRET"
	printf "}" # no new line here
done < <(curl 'https://bs.wgzeyu.com/songs/readme.md' | sed -n '/^#/,$p' | grep -E '^\s*\|' | grep -E '\|\s*$' | grep -v '不含曲包')
echo ']'
