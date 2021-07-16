#!/bin/bash

echo '======================================' >&2
echo "try reload nginx..."
curl -v --unix-socket /run/sockets/nginx.reload.sock http://_/ >&2

true
echo '======================================' >&2
