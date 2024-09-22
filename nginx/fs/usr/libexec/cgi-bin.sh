#!/usr/bin/bash
set -Euo pipefail
shopt -s extglob nullglob globstar shift_verbose

# CONFIG_ROOT = /run/nginx
# STORE_ROOT = /run/contributed
declare -r TESTING_DIR="/tmp/testing"

function log() {
	echo "[script] $*" >&2
}
function slog() {
	sed -E "s#^#\[script\] #" >&2
}
function response() {
	local -r CODE=$1 BODY="$2"
	log "complete - ${CODE}"
	printf "HTTP/1.0 666 Hello
Status: %s
Content-Type: text/html; charset=utf-8
Content-Length: %d
Connection: close
X-Doge: wow, such doge!

%s" "${CODE}" "${#BODY}" "${BODY}"
}

declare -r HTTP200='200 OK'
declare -r HTTP400='400 Bad Request'
declare -r HTTP404='404 Not Found'
declare -r HTTP503='503 Incorrect'

declare OUTPUT=''
function collect() {
	local -i RETURN=0
	local TMPF=$(mktemp --tmpdir 'collect.XXXXX.txt')
	if "$@" &>"${TMPF}"; then
		RETURN=0
	else
		RETURN=$?
	fi
	read -d '' -r OUTPUT <"${TMPF}"
	slog <"${TMPF}"
	unlink "${TMPF}"

	return ${RETURN}
}

# local WHICH_CONFIG=$1 CFG
# if [[ $WHICH_CONFIG == 'main' ]]; then
# 	CFG=/etc/nginx/nginx.conf
# else
# 	CFG="${TESTING_DIR}/nginx.conf"
# fi

function test_nginx() {
}

#######################################

log "http request: $ACTION + $WHAT"
# sleep 1

case $ACTION in
test)
	if collect test-config /etc/nginx/nginx.conf; then
		response "${HTTP200}" "${OUTPUT}"
	else
		response "${HTTP503}" "${OUTPUT}"
	fi
	;;
reload) ;;
status) ;;
config) ;;

*)
	response "${HTTP404}" "Invalid request"
	;;
esac
