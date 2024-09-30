#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit extglob nullglob globstar lastpipe shift_verbose

if ! mountpoint /data/records; then
	echo "/data/records must be mountpoint"
	exit 233
fi

touch /opt/app/bin/ERROR.TXT
mkdir -p /opt/app/bin/Config /data/debug /data/records /opt/app/bin/Temporary

declare -r CONFIG="/opt/app/bin/Config/DDTV_Config.ini"
if [[ ! -e ${CONFIG} ]]; then
	touch "${CONFIG}"
fi

function fill_config_field() {
	local -r NAME=$1 VALUE=$2
	local LINE="${NAME}=${VALUE}" DATA
	DATA=$(<"${CONFIG}")
	if echo "${DATA}" | grep -qF "${LINE}"; then
		return
	fi
	if echo "${DATA}" | grep -qF "${NAME}="; then
		echo "[config] replace ${NAME}"
		echo "${DATA}" | sed -E "s#.*${NAME}=.*#${LINE}#g" >"${CONFIG}"
	else
		echo "[config] create ${NAME}"
		{
			echo "${DATA}"
			echo "${LINE}"
		} >"${CONFIG}"
	fi
}

fill_config_field RecFileDirectory /data/records
fill_config_field DebugFileDirectory /data/debug
fill_config_field Port 11419
fill_config_field UseAgree True

chown -R 100:100 /opt/app/bin/Config /opt/app/bin/Temporary /opt/app/bin/ERROR.TXT
chown 100:100 /data /data/records /data/debug

echo "prestart complete!"
