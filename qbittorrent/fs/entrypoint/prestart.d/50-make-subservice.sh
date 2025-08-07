function make_sub() {
	local filepath=/opt/scripts/nginx.conf
	local socketfile=/usr/lib/systemd/system/socket-proxy.socket

	sed -i "s#qbittorrent#qbittorrent-${SUBSERVICE}#g" "${filepath}"
	sed -i "s#qbittorrent#qbittorrent-${SUBSERVICE}#g" "${socketfile}"
}
if [[ "${SUBSERVICE-}" ]]; then
	make_sub "${SUBSERVICE}"
	exportenv PROJECT_NAME "qbittorrent-${SUBSERVICE}"
	export PROJECT_NAME="qbittorrent-${SUBSERVICE}"
fi
