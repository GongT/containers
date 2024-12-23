#!/usr/bin/env bash

set -Eeuo pipefail

MENU_DIR='/data/content/00 目录'
rm -rf "${MENU_DIR}"
mkdir -p "${MENU_DIR}"

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

	echo "[${TITLE_SECRET}] ${TITLE_LINK}" >&2
	ln -s "../$TITLE_SECRET" "${MENU_DIR}/${TITLE_ESCAPE}"

	echo "{"
	echo "dir: /data/content/$TITLE_SECRET"
	echo "use_relay_server: false"
	echo "use_tracker: true"
	echo "search_lan: true"
	echo "use_sync_trash: false"
	echo "overwrite_changes: true"
	echo "selective_sync: false"
	echo "secret: $TITLE_SECRET"
	echo "}"
done < <(curl 'https://bs.wgzeyu.com/songs/readme.md' | sed -n '/^#/,$p' | grep -E '^\s*\|' | grep -E '\|\s*$' | grep -v '不含曲包')
echo ']'
