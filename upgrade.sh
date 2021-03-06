#!/usr/bin/env bash
set -Eeuo pipefail

cd /usr/lib/systemd/system

mapfile -t SCRIPT_LIST < <(grep 'INSTALLER_SCRIPT=' . -R | sed -E 's/^.+INSTALLER_SCRIPT=//g' | sort | uniq)

cd /tmp

export SYSTEMD_RELOAD=no
for FILE in "${SCRIPT_LIST[@]}"; do
	BASE=$(basename "$(dirname "$FILE")" .sh)
	echo -ne "\e[38;5;14m$BASE...\e[0m "

	LOG="/tmp/$BASE.log"
	if ! bash "$FILE" &>"$LOG"; then
		cat "$LOG" >&2
		echo -e "\e[38;5;9mFailed!\e[0m"
	else
		echo -e "\e[38;5;10mSuccess!\e[0m"
	fi
done

systemctl daemon-reload
