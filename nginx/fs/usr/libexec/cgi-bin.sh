#!/usr/bin/bash
set -Euo pipefail
shopt -s extglob nullglob globstar shift_verbose

# CONFIG_ROOT = /run/nginx/config
# STORE_ROOT = /run/nginx/contributed
# TESTING_DIR = /tmp/testing

function log() {
	echo "[script] $*" >&2
}
export -f log
function slog() {
	sed -E "s#^#\[script\] #" >&2
}
export -f slog
function response() {
	local -r CODE=$1 BODY="$2"$'\r\n'
	log "complete - ${CODE}"
	printf "HTTP/1.0 666 Hello\r
Status: %s\r
Content-Type: text/plain; charset=utf-8\r
Content-Length: %d\r
Connection: close\r
X-Doge: wow, such doge!\r
\r
%s" "${CODE}" "${#BODY}" "${BODY}"
	exit
}

declare -r HTTP200='200 OK'
declare -r HTTP400='400 Bad Request'
declare -r HTTP404='404 Not Found'
declare -r HTTP503='503 Incorrect'

declare OUTPUT=''
function collect() {
	local -i RETURN=0
	if OUTPUT=$("$@" 2>&1); then
		RETURN=0
	else
		RETURN=$?
		log ":: call [$*] return ${RETURN}"
	fi
	echo "${OUTPUT}" | slog
	OUTPUT=$(printf 'error %d while execute command %s\n%s\n' "${RETURN}" "$*" "${OUTPUT}")

	return ${RETURN}
}
export -f collect

function empty_dir() {
	local DIR=$1
	if [[ ! -d ${DIR} ]]; then
		mkdir -p "${DIR}"
		return
	fi
	find "${DIR}" -mindepth 1 -maxdepth 1 -exec rm -rf '{}' \;
}
export -f empty_dir

#######################################

function main() {
	log "[[request]] $ACTION + $WHAT"
	# sleep 1

	case $ACTION in
	test)
		if collect with-config /usr/libexec/nginx-config-test.sh /etc/nginx/nginx.conf; then
			response "${HTTP200}" "${OUTPUT}"
		else
			response "${HTTP503}" "${OUTPUT}"
		fi
		;;
	reload)
		if collect with-config /usr/libexec/nginx-config-reload.sh; then
			response "${HTTP200}" "${OUTPUT}"
		else
			response "${HTTP503}" "${OUTPUT}"
		fi
		;;
	delete)
		if [[ -z ${WHAT} ]]; then
			response "${HTTP400}" "missing operate"
		fi
		if [[ -e "${STORE_ROOT}/${WHAT}.tar" ]]; then
			log "remove file ${WHAT}.tar"
			rm -f "${STORE_ROOT}/${WHAT}.tar"
			if ! collect lock-config /usr/libexec/rebuild-config-folder.sh; then
				log "failed rebuild config!!!"
			fi
		else
			log "nothing to remove"
			OUTPUT="not exists"
		fi
		response "${HTTP200}" "${OUTPUT}"
		;;
	config)
		if [[ -z ${WHAT} ]]; then
			response "${HTTP400}" "missing operate"
		fi

		TMPF=$(mktemp --tmpdir "config-${WHAT}-XXXXX.tar")
		cat >"${TMPF}"
		trap "rm -rf '${TMPF}' &>/dev/null" EXIT

		log "  * check tarball valid (${TMPF})"
		if ! collect tar -tf "${TMPF}"; then
			log "invalid tar file"
			response "${HTTP400}" "${OUTPUT}"
			return
		fi

		declare -xr STORE_TARGET="${STORE_ROOT}/${WHAT}.tar"
		log "  * check config difference (${STORE_TARGET})"
		if OUTPUT=$(diff -s "${STORE_TARGET}" "${TMPF}" 2>&1); then
			log "${OUTPUT}"
			response "${HTTP200}" "${OUTPUT}"
			return
		fi
		log "${OUTPUT}"

		if OUTPUT=$(lock-config __processing_uploaded "${TMPF}" "${STORE_TARGET}"); then
			response "${HTTP200}" "${OUTPUT}"
		else
			response "${HTTP400}" "${OUTPUT}"
		fi
		;;
	*)
		response "${HTTP404}" "Invalid request"
		;;
	esac
}

function __processing_uploaded() {
	set -Euo pipefail
	shopt -s extglob nullglob globstar shift_verbose

	local TMPF=$1 STORE_TARGET=$2

	log "  * testing new config files"
	empty_dir "${TESTING_DIR}"
	cp -r "${CONFIG_ROOT}/." "${TESTING_DIR}"
	tar -xf "${TMPF}" -C "${TESTING_DIR}" &>/dev/null
	link-effective test
	config-file-macro /etc/nginx

	if nginx -t 2>&1; then
		log "    - ok"

		log "  * move to state store"
		mv "${TMPF}" "${STORE_TARGET}"
		log "  * extract main config"
		tar -xf "${STORE_TARGET}" -C "${CONFIG_ROOT}" &>/dev/null

		link-effective main
		config-file-macro "${CONFIG_ROOT}"

		log "signal nginx to reload"
		nginx -s reload 2>&1

		declare R=0
	else
		log "    - failed"
		link-effective main

		declare R=1
	fi

	log "  * done."
	return ${R}
}

export -f __processing_uploaded
main || true
