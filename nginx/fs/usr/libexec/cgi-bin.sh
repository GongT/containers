#!/usr/bin/bash
set -Euo pipefail
shopt -s extglob nullglob globstar shift_verbose

# CONFIG_ROOT = /run/nginx
# STORE_ROOT = /run/contributed
# TESTING_DIR = /tmp/testing

function log() {
	echo "[script] $*" >&2
}
function slog() {
	sed -E "s#^#\[script\] #" >&2
}
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

	return ${RETURN}
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
# local WHICH_CONFIG=$1 CFG
# if [[ $WHICH_CONFIG == 'main' ]]; then
# 	CFG=/etc/nginx/nginx.conf
# else
# 	CFG="${TESTING_DIR}/nginx.conf"
# fi
function test_config() {
	local -r NAME=$1 TARF=$2

	if ! collect tar -tf "${TARF}"; then
		log "invalid tar file"
		return 1
	fi

	log "testing new config files"
	empty_dir "${TESTING_DIR}"
	cp -r "${CONFIG_ROOT}/." "${TESTING_DIR}"
	tar -xf "${TARF}" -C "${TESTING_DIR}" >/dev/null
	link-effective test

	if collect nginx -t; then
		log "    - ok"

		mv "${TARF}" "${STORE_ROOT}/${WHAT}.tar"
		tar -xf "${STORE_ROOT}/${WHAT}.tar" -C "${CONFIG_ROOT}" >/dev/null
		local R=0
	else
		log "    - failed"

		unlink "${TARF}"
		local R=1
	fi

	link-effective main
	return ${R}
}

#######################################

log "http request: $ACTION + $WHAT"
# sleep 1

case $ACTION in
test)
	if test-config /etc/nginx/nginx.conf; then
		response "${HTTP200}" "${OUTPUT}"
	else
		response "${HTTP503}" "${OUTPUT}"
	fi
	;;
reload) ;;
status) ;;
config)
	TMPF=$(mktemp --tmpdir "config-${WHAT}-XXXXX.tar")
	cat >"${TMPF}"
	if test_config "${WHAT}" "${TMPF}"; then
		log "signal nginx to reload"
		O=$(nginx -s reload 2>&1)
		response "${HTTP200}" "${O}"
	else
		response "${HTTP400}" "${OUTPUT}"
	fi
	;;
*)
	response "${HTTP404}" "Invalid request"
	;;
esac
