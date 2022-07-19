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

mapfile -t COMPLETE_LIST < <(rpm -ql "crypto-policies" \
	| grep -v --fixed-strings -- '/.build-id' \
	| grep -v --fixed-strings -- '/usr/share/doc' \
	| grep -v --fixed-strings -- '/usr/share/man' \
	| grep -v --fixed-strings -- '/var/cache' \
	| grep -v --fixed-strings -- '/var/log' \
	| grep -v --fixed-strings -- '/run' \
	| sort | uniq)
FILE_LIST=()
for I in "${COMPLETE_LIST[@]}"; do
	if ! [[ -d $I ]]; then
		FILE_LIST+=("$I")
	fi
done

collect_system_file "${FILE_LIST[@]}"

collect_dist_root
copy_collected_dependencies
