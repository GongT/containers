function make_sub() {
	local name=$1
	local filepath=/opt/scripts/nginx.conf

	sed -i "s#qbittorrent#qbittorrent-${name}#g" "$filepath"
}
if [[ "${SUBSERVICE-}" ]]; then
	make_sub "${SUBSERVICE}"
fi
