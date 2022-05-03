#!/usr/bin/env bash

set -Eeuo pipefail

function build_json_line() {
	local TITLE=$1
	local SECRET=$2
	local DIR

	DIR=$(echo -n "/data/content/$TITLE" | jq --raw-input --compact-output --monochrome-output '.')
	cat <<-JSON | sed ""
		{ "dir": $DIR, "use_relay_server": true, "use_tracker": true, "search_lan": true, "use_sync_trash": false, "overwrite_changes": true, "selective_sync": false, "secret": "$SECRET" }
	JSON
}

TMPF=$(mktemp)
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

	build_json_line "$TITLE_LINK" "$TITLE_SECRET" >>"$TMPF"
done < <(curl 'https://bs.wgzeyu.com/songs/readme.md' | sed -n '/^#/,$p' | grep -E '^\s*\|' | grep -E '\|\s*$' | grep -v '不含曲包')
# build_json_line a b

jq --join-output --monochrome-output --slurp '.' <"$TMPF"
rm -f "$TMPF"
