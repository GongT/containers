#!/usr/bin/env bash
set -uo pipefail

declare -r CROOT_DIR="/run/nginx/contribute"
declare -r MASTER_CONTROL_DIR="${CROOT_DIR}/.master"
mkdir -p "${MASTER_CONTROL_DIR}"

declare -r INDEX_DIR="/tmp/testing/effective"

cd "${MASTER_CONTROL_DIR}"
rm -f "request.fifo"
mkfifo "request.fifo"

log() {
	printf "\e[2m[reload] %s\e[0m" "$*"
}
err() {
	printf "\e[38;5;9m[reload] %s\e[0m" "$*" >&2
}

function recreate_dir() {
	local DIR=$1
	rm -rf "${DIR}"
	mkdir -p "${DIR}"
}
function empty_dir() {
	local FILE DIR=$1
	if [[ ! -d ${DIR} ]]; then
		mkdir -p "${DIR}"
		return
	fi
	find "${DIR}" -mindepth 1 -maxdepth 1 -exec rm -rf '{}' \;
}
function build_directory() {
	local -r DEST=$1
	shift
	for ITEM; do
		(
			cd "${ITEM}" || return 1
			find . -type f -not -path '*/.*' -print0 | xargs -0 --no-run-if-empty cp --parents -t "${DEST}"
		)
	done
}

while cat "request.fifo" >/dev/null; do
	log "someone notify update:"
	if ! nginx -t &>/dev/null; then
		err "already in failed state, ignore reloading."
		continue
	fi

	declare -a CHANGE=() UNCHANGE=() DELETED=()
	for STATE_FILE in */.control/state; do
		STATE=$(<"${STATE_FILE}")
		ITEM=${STATE_FILE%%/*}

		if [[ ${STATE} == "active" ]]; then
			UNCHANGE+=("${I}")
			log "  - ${I}"
		elif [[ ${STATE} == "pending" ]]; then
			CHANGE+=("${I}")
			log "  * ${I}"
		elif [[ ${STATE} == "delete" || ${STATE} == "error"* ]]; then
			DELETED+=("${I}")
			log "  x ${I}"
		else
			log "  ? ${I} (invalid: ${STATE})"
		fi
	done

	if [[ ${#CHANGE[@]} -eq 0 && ${#DELETED[@]} -eq 0 ]]; then
		log "not found pending or delete."
		continue
	fi
	log "found ${#CHANGE[@]} pending, ${#DELETED[@]} delete."

	recreate_dir "/tmp/testing"
	cp -r /etc/nginx/. /tmp/testing
	unlink "${INDEX_DIR}"

	__recreate() {
		recreate_dir "${INDEX_DIR}"
		if [[ ${#UNCHANGE[@]} -gt 0 ]]; then
			build_directory "${INDEX_DIR}" "${UNCHANGE[@]}"
		fi
	}

	__recreate
	for ITEM in "${CHANGE[@]}"; do
		log "testing ${ITEM}:"
		build_directory "${INDEX_DIR}" "${ITEM}"

		ensure-sslcfg "/tmp/testing/nginx.conf" || true
		if nginx -t -c "/tmp/testing/nginx.conf" &>/tmp/merge.test.output.txt; then
			echo "  + success"
			echo "active" >"${ITEM}/.control/state"
			UNCHANGE+=("${ITEM}")
		else
			cat /tmp/merge.test.output.txt
			err "  ! failed"
			{
				echo "error"
				cat /tmp/merge.test.output.txt
			} >"${ITEM}/.control/state"

			__recreate
		fi
	done

	log "test complete"
	rm -rf "${EFFECTIVE_DIR}.new"
	mv "${INDEX_DIR}" "${EFFECTIVE_DIR}.new"
	mv "${EFFECTIVE_DIR}.new" "${EFFECTIVE_DIR}"

	if nginx -t && nginx -s reload; then
		log "reload complete"
	else
		err "result can not pass test"
	fi

	sleep 5
done
