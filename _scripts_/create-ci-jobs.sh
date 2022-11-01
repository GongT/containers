#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
cd ..

is_allowed() {
	local BLACKLIST=(bitcoin-peer ethereum-peer virtual-gateway-bridge proxyclient dandan-api nodered homeassistant proxyserver-nat)
	local match="$1" e
	for e in "${BLACKLIST[@]}"; do
		if [[ $e == "$match" ]]; then
			return 1
		fi
	done
}

declare -i cron_day=1

mapfile -d '' -t BUILD_FILES < <(find . -maxdepth 2 -name build.sh -print0 | sort --zero-terminated --dictionary-order)

TABLE="| Container | Link | Build Status |
|----:|:----|:----:|
"
for i in "${BUILD_FILES[@]}"; do
	PROJ=$(basename "$(dirname "$i")")

	if ! is_allowed "$PROJ"; then
		continue
	fi

	F=".github/workflows/generated-build-$PROJ.yaml"

	sed "s#{{PROJ}}#$PROJ#g" _scripts_/template.yaml >"$F"
	sed -i "s#{{thisfile}}#$F#g" "$F"

	if [[ $cron_day -ge 28 ]]; then
		cron_day=1
	else
		cron_day=$((cron_day + 1))
	fi
	sed -i "s#{{cron_day}}#$cron_day#g" "$F"

	TABLE+="| $PROJ "
	TABLE+="| https://hub.docker.com/r/gongt/$PROJ "
	TABLE+="| [![$PROJ](https://github.com/GongT/containers/workflows/$PROJ/badge.svg)](https://github.com/GongT/containers/actions?query=workflow%3A$PROJ)"
	TABLE+=" |"
	TABLE+=$'\n'
done

DATA=$(sed -n "/StatusTable:/{p; :a; N; /:StatusTable/!ba; s/.*\n/__TABLE_BODY__/}; p" README.md)
DATA="${DATA/__TABLE_BODY__/"$TABLE"}"

echo "$DATA" >README.md
