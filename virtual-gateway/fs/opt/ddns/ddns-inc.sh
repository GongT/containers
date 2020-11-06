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
	API_LIST+=(http://show-my-ip.gongt.me https://api.ipify.org)
fi

function call_curl() {
	pecho "  - /usr/bin/curl --no-progress-meter -$NET_TYPE $1" >&2
	local OUT
	OUT=$(/usr/bin/curl -v --no-progress-meter -$NET_TYPE "$1" | grep -oE '[0-9]+.[0-9]+.[0-9]+.[0-9]+')
	pecho "    $OUT" >&2
	if [[ -z $OUT ]]; then
		return 1
	fi
	if [[ ${CURRENT_IP_OUTPUT:-} ]]; then
		for i in "${CURRENT_IP_OUTPUT[@]}"; do
			if [[ $OUT == "$i" ]]; then
				echo -n "${i}"
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
			-d "password=${DSNS_KEY}"; then
			break
		fi
	done
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
