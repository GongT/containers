#!/usr/bin/bash

if [[ -z ${CONFIG_FILE_LOCK-} ]]; then
	source /etc/environment
fi

declare -a LOCK_ARG=() CMDS=()
STATE=lock
for ARG; do
	if [[ ${ARG} == '--' ]]; then
		STATE=args
		continue
	fi

	if [[ ${STATE} == lock ]]; then
		LOCK_ARG+=("${ARG}")
	else
		CMDS+=("${ARG}")
	fi
done
if [[ ${#CMDS[@]} -eq 0 ]]; then
	echo "missing commandline" >&2
	exit 250
fi

# touch "${CONFIG_FILE_LOCK}"
# echo "aquire ${CONFIG_FILE_LOCK}"
declare -i RETRY=0
while true; do
	flock --timeout 4 "${LOCK_ARG[@]}" --conflict-exit-code 250 "${CONFIG_FILE_LOCK}" bash -c 'echo $$ > "${CONFIG_FILE_LOCK}"; "$@"' -- "${CMDS[@]}"
	RET=$?

	if [[ ${RET} -eq 250 ]]; then
		PID=$(<"${CONFIG_FILE_LOCK}")
		CMD=$(cat "/proc/${PID}/cmdline" | tr '\0' ' ')
		echo "process ${PID}(${CMD}) is holding lock" >&2
		RETRY+=1

		if [[ ${RETRY} -gt 6 ]]; then
			echo "still not able to aquire lock" >&2
			exit 250
		fi

		sleep 1
	else
		break
	fi
done
# echo "release ${CONFIG_FILE_LOCK}"

exit $RET
