#!/usr/bin/bash

if [[ "$TEMP_DISABLE_RELOAD" ]]; then
	echo "reload行为已被临时禁用"
	exit 0
fi

if [[ -e /run/sockets/.nginx.reload.sh ]]; then
	source /run/sockets/.nginx.reload.sh
else
	echo "nginx 未启动."
	exit 0
fi
