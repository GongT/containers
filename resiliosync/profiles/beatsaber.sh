#!/usr/bin/env bash

set -Eeuo pipefail

export MENU_DIR='/data/content/00 目录'
rm -rf "${MENU_DIR}"
mkdir -p "${MENU_DIR}"

function ensure_symlink() {
	local LINK="$1"
	local TARGET="$2"
	echo "create link '$LINK'"

	if [[ -L $LINK ]]; then
		local CURR="$(realpath "$LINK")"
		echo "  - found exists link to $CURR"
		if [[ $CURR != "$TARGET" ]]; then
			unlink "$LINK"
		else
			return 0
		fi
	elif [[ -e $LINK ]]; then
		if [[ -d $LINK ]] && rmdir "$LINK"; then
			echo "  - removed empty directory: $LINK"
		else
			echo "ERROR: $LINK exists but not symlink"
			exit 66
		fi
	fi

	echo "  - creating symlink to $TARGET"
	ln -s --relative -T "$TARGET" "$LINK"
}

function create_link() {
	local TITLE_ESCAPE LINK_FILE TITLE_SECRET="$1"
	TITLE_ESCAPE=$(echo "${TITLE_LINK}" | sed 's#[\\\/:*?"<>|]##g')
	LINK_FILE="${MENU_DIR}/${TITLE_ESCAPE}"

	echo "[${TITLE_SECRET}] ${TITLE_LINK}" >&2
	ensure_symlink "${LINK_FILE}" "/data/content/$TITLE_SECRET"
}

function process_line() {
	local -r line="$1"
	local TITLE_SECRET

	TITLE_SECRET=$(echo "$line" | awk -F ' *\\| *' '{print $5}' | sed -E 's#[^0-9a-zA-Z]##g')
	if [[ $(echo -n "$TITLE_SECRET" | wc -c) -ne 33 ]]; then
		echo "===================================" >&2
		echo "Invalid Line: hash not equals to 33" >&2
		echo "$line" >&2
		echo "===================================" >&2
	fi

	create_link "${TITLE_SECRET}"

	printf "{\n"
	printf '\t"dir": "%s",\n' "/data/content/$TITLE_SECRET"
	printf '\t"use_relay_server": false,\n'
	printf '\t"use_tracker": true,\n'
	printf '\t"search_lan": true,\n'
	printf '\t"use_sync_trash": false,\n'
	printf '\t"overwrite_changes": true,\n'
	printf '\t"selective_sync": false,\n'
	printf '\t"secret": "%s"\n' "$TITLE_SECRET"
	printf "}\n"
}

if ! [[ -e /tmp/readme.md ]]; then
	echo "downloading readme.md"
	curl 'https://bs.wgzeyu.com/songs/readme.md' >/tmp/readme.md
fi

SIGFOUND=
while IFS= read -r line; do
	TITLE_LINK=$(echo "$line" | awk -F ' *\\| *' '{print $2}' | sed -E 's#^.*\[(.+)].*$#\1#g')

	if [[ $TITLE_LINK =~ ^-+$ ]]; then
		SIGFOUND=yes
		continue
	elif [[ ! $SIGFOUND ]]; then
		continue
	fi

	process_line "${line}"
done < <(cat /tmp/readme.md | sed -n '/^#/,$p' | grep -E '^\s*\|' | grep -E '\|\s*$' | grep -v '不含曲包')
