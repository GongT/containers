set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

pushd /usr/lib/systemd/system &> /dev/null

LIST=($(
	systemctl list-unit-files '*.pod@.service' '*.pod.service' --all --no-pager \
		| grep enabled \
		| sed -E 's#\.pod@?\.service.+$##g'
))

popd &> /dev/null

export SYSTEMD_RELOAD=no
for NAME in "${LIST[@]}"; do
	if [[ -e "$NAME.service" ]]; then
		systemctl disable "$NAME" --now &> /dev/null || true
		unlink "$NAME.service"
	fi

	echo -ne "\e[38;5;14m${NAME}...\e[0m "

	TEMPF=$(mktemp)
	LOG="$TEMPF.log"
	bash -c "bash '${NAME}/install-service.sh' ; echo -n \$? > '$LOG.ret'" &> "$LOG"

	if [[ "$(< $LOG.ret)" != 0 ]]; then
		echo -e "\e[38;5;9mFailed!\e[0m"
		cat "$LOG" >&2
	else
		echo -e "\e[38;5;10mSuccess!\e[0m"
	fi
done

systemctl daemon-reload
