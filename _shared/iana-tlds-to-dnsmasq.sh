#!/usr/bin/env bash

STEP="IANA根域名列表"
TLDS_URL="https://data.iana.org/TLD/tlds-alpha-by-domain.txt"
tlds_etag() {
	http_get_etag "$TLDS_URL"
}
tlds_update() {
	local FILE LINE LINES TMPF
	TMPF=$(create_temp_file iana)

	FILE=$(download_file_force "$TLDS_URL" tlds.txt)
	mapfile -t LINES <"$FILE"
	for LINE in "${LINES[@]}"; do
		if [[ $LINE == '#'* ]]; then
			continue
		fi
		echo "address=/${LINE,,}/::"
		echo "server=/${LINE,,}/${REAL_DNS_SERVER}"
	done >"$TMPF"

	buildah copy "$1" "$TMPF" "${SAVE_TO:-/etc/dnsmasq.d/iana.conf}"
}
buildah_cache "$1" tlds_etag tlds_update
