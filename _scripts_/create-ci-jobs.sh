#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
cd ..
source common/package/include.sh
printf '\ec'

declare -i cron_day=1
declare -r TEMPLATE="_scripts_/template.yaml"
declare -r TMPOUT="/tmp/output.txt"
mkdir -p ".github/workflows"

mapfile -d '' -t BUILD_FILES < <(find . -maxdepth 2 -name build.sh -print0 | sort --zero-terminated --dictionary-order)

TABLE="| Container | Link | Build Status |
|----:|:----|:----:|
"
for i in "${BUILD_FILES[@]}"; do
	if [[ -e $(realpath -m "$i/../disabled") ]]; then
		continue
	fi

	PROJ=$(basename "$(dirname "$i")")
	OUTPUT=".github/workflows/generated-build-$PROJ.yaml"

	save_cursor_position
	printf "\e[?1049h\e[1;1H 🔶 %s\n" "${PROJ}" >&2
	trap 'printf "\e[?1049l\n\e[J"; restore_cursor_position' EXIT
	if bash "common/split-into-steps.sh" "$i" "$TEMPLATE" >"$OUTPUT" 2> >(tee "${TMPOUT}" >&2); then
		printf '\e[?1049l\e[J' >&2
		restore_cursor_position
		trap - EXIT
		printf " ✅ %s: ok.\n" "${PROJ}" >&2
	else
		printf '\e[?1049l\e[J' >&2
		restore_cursor_position
		trap - EXIT

		MESG=""
		printf -v MESG "\e[38;5;9m ❌ %s failed! \e[2m(./common/split-into-steps.sh %s %s > %s)\e[0m" "${PROJ}" "$i" "$TEMPLATE" "$OUTPUT"

		echo "${MESG}" >&2
		cat "${TMPOUT}" >&2
		echo "${MESG}" >&2

		unlink "${TMPOUT}"
		exit 1
	fi

	CONTENT=$(<"${OUTPUT}")
	CONTENT=${CONTENT//"{{PROJ}}"/"$PROJ"}
	CONTENT=${CONTENT//"{{thisfile}}"/"$OUTPUT"}
	CONTENT=${CONTENT//"{{cron_day}}"/"$cron_day"}
	echo "${CONTENT}" >"${OUTPUT}"

	if [[ $cron_day -ge 28 ]]; then
		cron_day=1
	else
		cron_day=$((cron_day + 1))
	fi

	TABLE+="| $PROJ "
	TABLE+="| https://hub.docker.com/r/gongt/$PROJ "
	TABLE+="| [![$PROJ](https://github.com/GongT/containers/workflows/$PROJ/badge.svg)](https://github.com/GongT/containers/actions?query=workflow%3A$PROJ)"
	TABLE+=" |"
	TABLE+=$'\n'
done

DATA=$(sed -n "/StatusTable:/{p; :a; N; /:StatusTable/!ba; s/.*\n/__TABLE_BODY__/}; p" README.md)
DATA="${DATA/__TABLE_BODY__/"$TABLE"}"

echo "$DATA" >README.md
