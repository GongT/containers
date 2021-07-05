#!/usr/bin/env bash

set -Eeuo pipefail

if ! [[ ${WATCH_LIVEROOM:-} -gt 0 ]]; then
	echo "没有环境变量： WATCH_LIVEROOM"
	exit 233
fi

cd /data

sed -i "s/114514/$WATCH_LIVEROOM/g" config.json

exec /usr/bin/dotnet /app/BililiveRecorder.Cli.dll run /data
