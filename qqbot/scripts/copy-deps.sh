#!/usr/bin/env bash

set -Eeuo pipefail

cd "$INSTALL_TARGET"

mkdir -p /etc/ld.so.conf.d/
echo "/mnt/install/usr/lib/server" >/etc/ld.so.conf.d/java.conf
ldconfig

echo "options timeout:10
options attempts:5
nameserver 127.0.0.1
" >/etc/resolv.conf

mapfile -t BINARYS < <(find usr/bin -type f)
mapfile -t DLOBJS < <(find usr/lib -name '*.so' -type f)
for I in "${BINARYS[@]}" "${DLOBJS[@]}"; do
	if [[ $I == */libawt_xawt.so ]] \
		|| [[ $I == */libjawt.so ]] \
		|| [[ $I == */libjsound.so ]] \
		|| [[ $I == */libsplashscreen.so ]]; then
		continue
	fi
	echo "resolve dependency of $I"
	collect_binary_dependencies "$I"
done

copy_collected_dependencies
