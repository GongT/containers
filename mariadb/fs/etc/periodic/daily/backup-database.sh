#!/usr/bin/env bash

set -Eeuo pipefail

BACKPATH="/backup/$(date +%Y)/$(date +%M)/$(date +%d)"

mkdir -p "$BACKPATH"
for DB in $(mysql -e 'show databases' -s --skip-column-names); do
	echo -n " * $DB - "
	if [[ "$DB" = "information_schema" ]] || [[ "$DB" = "performance_schema" ]]; then
		echo "ignore"
		continue
	fi

	if [[ "$DB" = '#'* ]]; then
		echo "ignore"
		continue
	fi

	FILE="$BACKPATH/$DB.sql.7z"
	echo "backup to $FILE"

	if [[ -e "$FILE" ]]; then
		rm -rf "$FILE"
	fi
	mysqldump "$DB" | 7z a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=64m -ms=on -bso0 -bsp0 -si "$FILE"
done
