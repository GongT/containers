if [[ -z $NET_TYPE ]]; then
	echo 'Error NET_TYPE' >&2
	exit 1
fi
export http_proxy="" https_proxy="" all_proxy="" HTTP_PROXY="" HTTPS_PROXY="" ALL_PROXY=""

function pecho() {
	echo "($NET_TYPE) $*"
}

declare -a API_LIST
API_LIST=()
if [[ $NET_TYPE -eq 6 ]]; then
	API_LIST+=(http://checkip.dns.he.net https://api6.ipify.org)
else
	API_LIST+=(http://checkip.dns.he.net https://api.ipify.org)
fi

function call_curl() {
	pecho "  - /usr/bin/curl --no-progress-meter -$NET_TYPE $1" >&2
	local OUT
	OUT=$(/usr/bin/curl --no-progress-meter -$NET_TYPE "$1")
	if [[ $NET_TYPE == 4 ]]; then
		OUT=$(echo "$OUT" | grep -oE '[0-9]+.[0-9]+.[0-9]+.[0-9]+')
	else
		OUT=$(echo "$OUT" | grep -oE '\b[0-9a-f:]+:[0-9a-f:]+\b')
	fi
	pecho "    $OUT" >&2
	if [[ -z $OUT ]]; then
		return 1
	fi
	if [[ ${CURRENT_IP_OUTPUT:-} ]]; then # only ipv6 have this
		local IP
		for IP in "${CURRENT_IP_OUTPUT[@]}"; do
			if [[ $OUT == "$IP" ]]; then
				echo -n "${IP}"
				return 0
			fi
		done
		return 1
	else
		pecho "    dont check ip valid." >&2s
		echo -n "${OUT}"
		return 0
	fi
}

function request_url() {
	local i
	for i in "${API_LIST[@]}"; do
		if call_curl "$i"; then
			return
		fi
		sleep 2
		if call_curl "$i"; then
			return
		fi
	done
	echo ""
}

function x() {
	pecho " + $*"
	"$@"
}

function ddns_script() {
	pecho "request update api..."
	while true; do
		sleep 1
		if x /usr/bin/curl --no-progress-meter "-$NET_TYPE" "https://dyn.dns.he.net/nic/update" \
			-d "hostname=${DDNS_HOST}" \
			-d "password=${DDNS_KEY}"; then
			break
		fi
	done
	pecho ""
	pecho "update done."
}

declare -r SAVE_FILE="/storage/save.ip.$NET_TYPE"
declare -r SAVE_FILE_LIST="/storage/save.ip.$NET_TYPE.list"
function exit_if_same() {
	local IP="$1" SAVED
	if [[ -e $SAVE_FILE ]]; then
		SAVED=$(<"$SAVE_FILE")
		if [[ $SAVED == "$IP" ]]; then
			pecho "current IP output not change"
			exit 0
		else
			pecho "    saved IP output has change. saved one is: $SAVED"
		fi
	else
		pecho "    no saved IP."
	fi
}
function exit_if_same_list() {
	local SLIST SAVED
	if ! [[ -e $SAVE_FILE_LIST ]]; then
		pecho "    no saved IP list."
		return
	fi
	SAVED=$(<"$SAVE_FILE_LIST")

	SLIST=$(
		local I
		for I; do
			echo "$I"
		done | sort -u -
	)

	if [[ $SAVED == "$SLIST" ]]; then
		pecho "current IP list output not change"
		exit 0
	else
		pecho "    saved IP list output has change."
	fi
}

function save_current_ip() {
	echo "$1" >"$SAVE_FILE"
	pecho "state saved."
}
function save_current_ip_list() {
	local I
	for I; do
		echo "$I"
	done | sort -u - >"$SAVE_FILE_LIST"
	pecho "list state saved."
}
