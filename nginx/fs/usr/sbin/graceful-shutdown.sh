#!/bin/sh

echo "#!/bin/sh

echo 'nginx container is not running...' >&2


" >/run/sockets/nginx.reload.sh
rm -f /run/sockets/nginx.reload.sock /run/sockets/http.sock /run/sockets/https.sock
