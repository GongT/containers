#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit extglob nullglob globstar lastpipe shift_verbose

touch /opt/app/bin/ERROR.txt
mkdir -p /opt/app/bin/Config
CONFIG="/opt/app/bin/Config/DDTV_Config.ini"
if [[ ! -e ${CONFIG} ]]; then
	touch "${CONFIG}"
fi
chown -R 100:100 /opt/app/bin/Config /opt/app/bin/ERROR.txt
chown 100:100 /data /data/records /data/debug

function fill_config_field() {

}

fill_config_field RecFileDirectory /data/records
fill_config_field DebugFileDirectory /data/debug
fill_config_field Port 11419
