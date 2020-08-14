#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ../common/functions-build.sh

info "preparing..."
RESULT=$(create_if_not powerdns-work gongt/alpine-init)

echo '
apk add pdns pdns-backend-sqlite3 nginx

rm -rf /etc/nginx /etc/pdns /var/www/ /etc/inittab /etc/init.d
mkdir -p /etc/nginx /etc/pdns /var/www/
mkdir -p /opt /data /run/nginx
' | buildah run $(use_alpine_apk_cache) "$RESULT" sh
info "required packages installed..."

mnt=$(buildah mount "$RESULT")
cat config/init.sql | gzip -c > "$mnt/opt/init.sql.gz"

cp -r config/etc -t "$mnt/"

cp config/start-*.sh "$mnt/opt"
chmod a+x "$mnt/opt/"start-*.sh

cp -r powerdns-webui/htdocs/. -t "$mnt/var/www/"


buildah umount "$RESULT"
info "config file copied..."

buildah config --cmd "/sbin/init" --port 53/udp --port 53/tcp --port 53000 "$RESULT"
buildah config --volume /data "$RESULT"
buildah config --author "GongT <admin@gongt.me>" --created-by "GongT" --label name=gongt/powerdns "$RESULT"
info "settings updated..."

buildah commit "$RESULT" gongt/powerdns
info "Done!"
