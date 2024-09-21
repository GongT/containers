#!/usr/bin/env bash
set -uo pipefail
shopt -s extglob nullglob globstar shift_verbose

if [[ -z ${EFFECTIVE_DIR-} ]]; then
	echo "missing EFFECTIVE_DIR" >&2
	exit 1
fi

declare -r CROOT_DIR="/run/nginx/contribute"
declare -r MASTER_CONTROL_DIR="${CROOT_DIR}/.master"
declare -r FIFO="${MASTER_CONTROL_DIR}/request.fifo"
declare -r INDEX_DIR="/tmp/testing/effective"

mkdir -p "${MASTER_CONTROL_DIR}"
cd "${CROOT_DIR}"

rm -f "${FIFO}"
mkfifo "${FIFO}"

log() {
	printf "\e[2m[reload] %s\e[0m\n" "$*"
}
err() {
	printf "\e[38;5;9m[reload] %s\e[0m\n" "$*" >&2
}

function recreate_dir() {
	local DIR=$1
	rm -rf "${DIR}"
	mkdir -p "${DIR}"
}
function empty_dir() {
	local DIR=$1
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

log "someone notify update:"
if ! nginx -t &>/dev/null; then
	err "already in failed state, ignore reloading."
	return 0
fi

declare -a CHANGE=() UNCHANGE=() DELETED=()
for STATE_FILE in */.control/state; do
	STATE=$(<"${STATE_FILE}")
	ITEM=${STATE_FILE%%/*}

	if [[ ${STATE} == "active" ]]; then
		UNCHANGE+=("${ITEM}")
		log "  - ${ITEM}"
	elif [[ ${STATE} == "pending" ]]; then
		CHANGE+=("${ITEM}")
		log "  * ${ITEM}"
	elif [[ ${STATE} == "delete" ]]; then
		DELETED+=("${ITEM}")
		log "  x ${ITEM} (delete)"
	elif [[ ${STATE} == "error"* ]]; then
		log "  x ${ITEM}"
	else
		log "  ? ${ITEM} (invalid: ${STATE})"
	fi
done

if [[ ${#CHANGE[@]} -eq 0 && ${#DELETED[@]} -eq 0 ]]; then
	log "not found pending or delete."
	return 0
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
		log "  + success"
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
cp -r "${INDEX_DIR}" "${EFFECTIVE_DIR}.new"
rm -rf "${EFFECTIVE_DIR}"
mv "${EFFECTIVE_DIR}.new" "${EFFECTIVE_DIR}"

for ITEM in "${DELETED[@]}"; do
	log "remove: ${ITEM}"
	rm -rf "${ITEM}"
done

if nginx -t && nginx -s reload; then
	log "reload complete"
else
	err "result can not pass test"
fi
