#!/usr/bin/env bash

set -Eeuo pipefail

mkdir -p /etc/resolv.conf.d

NAME="/etc/resolv.conf.d/$1"
shift

rm -f "$NAME"
for I in "$@"; do
	echo "nameserver $I" >>"$NAME"
done
echo "rewrite: resolv.conf (add $NAME)" >&2

{
	if [[ "${RESOLVE_OPTIONS:-}" ]]; then
		echo "# RESOLVE_OPTIONS"
		echo "options $RESOLVE_OPTIONS"
	fi
	if [[ "${RESOLVE_SEARCH:-}" ]]; then
		echo "# RESOLVE_SEARCH"
		echo "options $RESOLVE_SEARCH"
	fi
	for I in /etc/resolv.conf.d/*; do
		echo "# content from $I"
		cat "$I"
	done
	if [[ "${NSS:-}" ]]; then
		echo "# NSS"
		mapfile -d ' ' -t NSS < <(echo "$NSS")
		for NS in "${NSS[@]}"; do
			echo "nameserver $NS"
		done
	fi
} >/etc/resolv.conf
