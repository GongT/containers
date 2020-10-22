if [[ -z $NET_TYPE ]]; then
	echo 'Error NET_TYPE' >&2
	exit 1
fi
export http_proxy="" https_proxy="" HTTP_PROXY="" HTTPS_PROXY=""

function pecho() {
	echo "($NET_TYPE) $*"
}

declare -a API_LIST
API_LIST=()
if [[ $NET_TYPE -eq 6 ]]; then
	API_LIST+=(https://api6.ipify.org)
else
	API_LIST+=(http://show-my-ip.gongt.me https://api.ipify.org)
fi

function call_curl() {
	pecho "------------------ try $1..." >&2
	local OUT
	OUT=$(/usr/bin/curl --no-progress-meter -$NET_TYPE "$1")
	pecho "$OUT" >&2
	pecho "------------------" >&2
	if [[ -z $OUT ]]; then
		return 1
	fi
	if [[ ${CURRENT_IP_LIST+ns} != ns ]]; then
		pecho "dont check ip valid." >&2s
		echo -n ${OUT}
		return 0
	fi
	for i in "${CURRENT_IP_LIST[@]}"; do
		if echo "$OUT" | grep -q "$i"; then
			echo -n ${i}
			return 0
		fi
	done
	return 1
}

function request_url() {
	for i in "${API_LIST[@]}"; do
		if call_curl "$i"; then
			return
		fi
		sleep 2
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

function ddns_script() {
	pecho "request update api..."
	/usr/bin/curl --no-progress-meter --silent "-$NET_TYPE" "https://dyn.dns.he.net/nic/update" \
		-d "hostname=${DDNS_HOST}" \
		-d "password=${DSNS_KEY}"
	pecho ""
	pecho "update done."
}

declare -r SAVE_FILE="/storage/save.ip.$NET_TYPE"
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

function save_current_ip() {
	echo "$1" >"$SAVE_FILE"
	pecho "state saved."
}