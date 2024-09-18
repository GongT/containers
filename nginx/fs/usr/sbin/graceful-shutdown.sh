#!/bin/sh

echo "#!/bin/sh

echo 'nginx container is not running...' >&2


" >/run/nginx/sockets/nginx.reload.sh
rm -f /run/nginx/sockets/nginx.reload.sock /run/nginx/sockets/http.sock /run/nginx/sockets/https.sock
