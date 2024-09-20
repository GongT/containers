#!/bin/bash

if [[ "$TEMP_DISABLE_RELOAD" ]]; then
	echo "reload temporary disabled..."
	exit 0
fi

echo '======================================' >&2
if [[ -e /run/nginx/contribute/.master/request.fifo ]]; then
	echo "notify nginx to reload."
	echo "acme" >/run/nginx/contribute/.master/request.fifo
else
	echo "not able to notify"
fi
echo '======================================' >&2
