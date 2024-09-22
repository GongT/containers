#!/usr/bin/env bash

printf '\ec'

export PROJECT_NAME=''

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
cd ..
source common/package/include.sh

declare -xi cron_day=1
declare -r TEMPLATE="_scripts_/template.yaml"
declare -r TMPOUT="/tmp/thisfile.txt"
declare -a PROJS=()

if [[ $# -eq 0 ]]; then
	NARGS=()
	find .github/workflows -maxdepth 1 -type f -name '*.yaml' -print0 | sort --zero-terminated | while read -d '' -r FILE; do
		NAME=$(basename "${FILE}" .yaml)
		NAME=${NAME#generated-build-}
		NARGS+=("${NAME}")
	done
	set -- "${NARGS[@]}"
fi

echo "generate $# projects."
for PROJECT_NAME; do
	export thisfile=".github/workflows/generated-build-$PROJECT_NAME.yaml"

	if [[ ! -e "${PROJECT_NAME}/build.sh" ]]; then
		printf " ❌ %s: missing.\n" "${PROJECT_NAME}" >&2
		rm -f "${thisfile}"
		continue
	fi
	if [[ -e "${PROJECT_NAME}/disabled" ]]; then
		printf " ⛔ %s: disabled.\n" "${PROJECT_NAME}" >&2
		rm -f "${thisfile}"
		continue
	fi

	CMDS=(bash "common/split-into-steps.sh" "${PROJECT_NAME}/build.sh" "$TEMPLATE" "$thisfile")

	save_cursor_position
	printf "\e[?1049h\e[1;1H 🔶 %s\n" "${PROJECT_NAME}" >&2
	if "${CMDS[@]}" &> >(tee "${TMPOUT}" >&2); then
		printf '\e[?1049l\e[J' >&2
		restore_cursor_position
		printf " ✅ %s: ok.\n" "${PROJECT_NAME}" >&2
		printf "     \e[2m%s\n\n" "${CMDS[*]}"
	else
		printf '\e[?1049l\e[J' >&2
		restore_cursor_position

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
