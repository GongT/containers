#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s inherit_errexit extglob nullglob globstar lastpipe shift_verbose

if [[ ! -e /etc/teamspeak/ts3server.ini ]]; then
	/opt/server/ts3server createinifile=1 inifile=/etc/teamspeak/ts3server.ini version
fi
if [[ ! -e /etc/teamspeak/ts3db_mariadb.ini ]]; then
	cp /opt/scripts/db.ini /etc/teamspeak/ts3db_mariadb.ini
fi
