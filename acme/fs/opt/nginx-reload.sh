#!/bin/bash

if [[ "$TEMP_DISABLE_RELOAD" ]]; then
	echo "reload temporary disabled..."
	exit 0
fi

echo '======================================' >&2
echo "try reload nginx..."
curl -v --unix-socket /run/sockets/nginx.reload.sock http://_/ >&2

true
echo '======================================' >&2
