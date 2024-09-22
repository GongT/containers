#!/bin/bash

if [[ "$TEMP_DISABLE_RELOAD" ]]; then
	echo "reload temporary disabled..."
	exit 0
fi

if [[ -e /run/sockets/.nginx.reload.sh ]]; then
	source /run/sockets/.nginx.reload.sh
else
	echo "nginx not started."
	exit 0
fi
