#!/usr/bin/env bash

STEP="IANA根域名列表"
TLDS_URL="https://data.iana.org/TLD/tlds-alpha-by-domain.txt"
tlds_etag() {
	http_get_etag "$TLDS_URL"
}
tlds_update() {
	local FILE LINE LINES MNT
	MNT=$(buildah mount "$1")
	FILE=$(download_file_force "$TLDS_URL" tlds.txt)
	mapfile -t LINES <"$FILE"
	for LINE in "${LINES[@]}"; do
		if [[ $LINE == '#'* ]]; then
			continue
		fi
		echo "address=/${LINE,,}/::"
		echo "server=/${LINE,,}/127.0.0.1#5353"
	done >"$MNT${SAVE_TO:-/etc/dnsmasq.d/iana.conf}"
}
buildah_cache2 "$1" tlds_etag tlds_update
