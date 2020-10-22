#!/usr/bin/env bash

set -Eeuo pipefail

mkdir -p /etc/resolv.conf.d

{
	if [[ "${RESOLVE_OPTIONS:-}" ]]; then
		echo "options $RESOLVE_OPTIONS"
	fi
	if [[ "${RESOLVE_SEARCH:-}" ]]; then
		echo "options $RESOLVE_SEARCH"
	fi
	if [[ "${NSS:-}" ]]; then
		mapfile -d ' ' -t NSS < <(echo "$NSS")
		for NS in "${NSS[@]}"; do
			echo "nameserver $NS"
		done
	fi
} >/etc/resolv.conf

NAME="/etc/resolv.conf.d/$1"
shift

rm -f "$NAME"
for I in "$@"; do
	echo "nameserver $I" >>"$NAME"
done

for I in /etc/resolv.conf.d/*; do
	cat "$I" >>/etc/resolv.conf
done

echo "rewrite: resolv.conf (add $NAME)" >&2
