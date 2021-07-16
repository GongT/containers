#!/usr/bin/env bash

set -Eeuo pipefail

cd "$INSTALL_TARGET"

for D in config var/log/nginx run tmp config.auto etc/ssl run/sockets etc/nginx; do
	mkdir -p "${D}"
done

collect_dist_binary_dependencies
collect_binary_dependencies /usr/bin/htpasswd /usr/bin/sed /usr/bin/curl /usr/bin/grep /usr/bin/openssl

mkdir -p etc/pki/tls
cp /etc/pki/tls/openssl.cnf etc/pki/tls

copy_dist_root
copy_collected_dependencies
