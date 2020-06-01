#!/bin/sh
echo '======================================' >&2
echo 'try reload nginx...'
if command -v curl &>/dev/null; then
	curl -v --unix-socket /run/sockets/nginx.reload.sock http://_/ >&2
else
	echo 'GET /' | nc local:/run/sockets/nginx.reload.sock
fi
echo '======================================' >&2
