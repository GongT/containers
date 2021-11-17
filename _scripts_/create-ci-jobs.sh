#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
cd ..

declare -i cron_hour=7

mapfile -d '' -t BUILD_FILES < <(find . -maxdepth 2 -name build.sh -print0 | sort --zero-terminated --dictionary-order)

TABLE="| Container | Link | Build Status |
|----:|:----|:----:|
"
for i in "${BUILD_FILES[@]}"; do
	PROJ=$(basename "$(dirname "$i")")
	F=".github/workflows/generated-build-$PROJ.yaml"

	sed "s#{{PROJ}}#$PROJ#g" _scripts_/template.yaml >"$F"
	sed -i "s#{{thisfile}}#$F#g" "$F"

	if [[ $cron_hour -ge 23 ]]; then
		cron_hour=0
	else
		cron_hour=$((cron_hour + 1))
	fi
	sed -i "s#{{cron_hour}}#$cron_hour#g" "$F"

	TABLE+="| $PROJ "
	TABLE+="| https://hub.docker.com/r/gongt/$PROJ "
	TABLE+="| [![$PROJ](https://github.com/GongT/containers/workflows/$PROJ/badge.svg)](https://github.com/GongT/containers/actions?query=workflow%3A$PROJ)"
	TABLE+=" |"
	TABLE+=$'\n'
done

DATA=$(sed -n "/StatusTable:/{p; :a; N; /:StatusTable/!ba; s/.*\n/__TABLE_BODY__/}; p" README.md)
DATA="${DATA/__TABLE_BODY__/"$TABLE"}"

echo "$DATA" >README.md
