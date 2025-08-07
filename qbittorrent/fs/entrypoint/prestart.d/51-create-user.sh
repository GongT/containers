UNAME=${USER_NAME:-}
UID=${USER_ID:-}
GID=${GROUP_ID:-}

if [[ ! "${UNAME}" ]]; then
	UNAME=media_rw
	UID=100
	GID=100
fi

unset USER_NAME USER_ID GROUP_ID

exportenv USER_NAME "${UNAME}"
system_ensure_group "$GID" users
system_ensure_user "$UID" "$UNAME" "$GID"

mkdir -p "/home/${UNAME}"

echo "User=${UNAME}" >> /usr/lib/systemd/system/qbittorrent.service

if ! [[ -e /opt/qBittorrent/config/qBittorrent.conf ]]; then
	log "first run."
	mkdir -p /opt/qBittorrent/config
	cp /opt/scripts/qBittorrent.conf /opt/qBittorrent/config/qBittorrent.conf
fi

chown -R "${UNAME}:users" "/home/${UNAME}" /opt/qBittorrent

unset UNAME UID GID
