#!/bin/sh
echo '======================================' >&2
echo 'try reload nginx...'
curl -v --unix-socket /run/sockets/nginx.reload.sock http://_/ >&2
echo '======================================' >&2
