set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
export ROOT="$(pwd)"

cd /usr/lib/systemd/system

function x() {
	echo -n "$*" >&2
	"$@" &>/dev/null
	echo " - $?" >&2
}
function remove_service() {
	cd "$ROOT"
	local N=$1
	local S="$N.service"

	INSTALL=$(grep -lE "create_pod_service_unit .*$N" ./*/install-service.sh)
	if [[ ! "$INSTALL" ]]; then
		echo "$N x"
		return
	fi
	echo "$N - ${INSTALL}"

	x systemctl disable $S
	x rm -f /usr/lib/systemd/system/$S
	x bash -c "bash $INSTALL &>/dev/null"
}
export -f remove_service x

/usr/bin/podman ps | awk '{print $NF}' | tail -n +2 | xargs -IF -n1 bash -c "remove_service F"
