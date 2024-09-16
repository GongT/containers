#!/usr/bin/env bash

set -Eeuo pipefail

export PROJECT_NAME=''

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
cd ..
source common/package/include.sh
printf '\ec'

declare -xi cron_day=1
declare -r TEMPLATE="_scripts_/template.yaml"
declare -r TMPOUT="/tmp/thisfile.txt"

mapfile -d '' -t BUILD_FILES < <(find . -maxdepth 2 -name build.sh -print0 | sort --zero-terminated --dictionary-order)

for i in "${BUILD_FILES[@]}"; do
	if [[ -e $(realpath -m "$i/../disabled") ]]; then
		continue
	fi
	export PROJECT_NAME=$(basename "$(dirname "$i")")

	if [[ ${1-} != '' && $1 != "${PROJECT_NAME}" ]]; then
		continue
	fi

	export thisfile=".github/workflows/generated-build-$PROJECT_NAME.yaml"

	save_cursor_position
	printf "\e[?1049h\e[1;1H 🔶 %s\n" "${PROJECT_NAME}" >&2
	trap 'printf "\e[?1049l\n\e[J"; restore_cursor_position' EXIT
	CMDS=(bash "common/split-into-steps.sh" "$i" "$TEMPLATE" "$thisfile")
	if "${CMDS[@]}" &> >(tee "${TMPOUT}" >&2); then
		printf '\e[?1049l\e[J' >&2
		restore_cursor_position
		trap - EXIT
		printf " ✅ %s: ok.\n" "${PROJECT_NAME}" >&2
		printf "     \e[2m%s\n\n" "${CMDS[*]}"
	else
		printf '\e[?1049l\e[J' >&2
		restore_cursor_position
		trap - EXIT

		MESG=""
		printf -v MESG "\e[38;5;9m ❌ %s failed! \e[2m(%s)\e[0m" "${PROJECT_NAME}" "${CMDS[*]}"

		echo "${MESG}" >&2
		cat "${TMPOUT}" >&2
		echo "${MESG}" >&2

		unlink "${TMPOUT}"
		exit 1
	fi

	if [[ $cron_day -ge 28 ]]; then
		cron_day=1
	else
		cron_day=$((cron_day + 1))
	fi
done
