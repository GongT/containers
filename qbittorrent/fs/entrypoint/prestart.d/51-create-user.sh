U_NAME=${USER_NAME:-}
U_ID=${USER_ID:-}
G_ID=${GROUP_ID:-}

if [[ ! "${U_NAME}" ]]; then
	U_NAME=media_rw
	U_ID=100
	G_ID=100
fi

unset USER_NAME USER_ID GROUP_ID

exportenv USER_NAME "${U_NAME}"
system_ensure_group "$G_ID" users
system_ensure_user "$U_ID" "$U_NAME" "$G_ID"

mkdir -p "/home/${U_NAME}"

echo "User=${U_NAME}" >> /usr/lib/systemd/system/qbittorrent.service

if ! [[ -e /opt/qBittorrent/config/qBittorrent.conf ]]; then
	log "first run."
	mkdir -p /opt/qBittorrent/config
	cp /opt/scripts/qBittorrent.conf /opt/qBittorrent/config/qBittorrent.conf
fi

chown -R "${U_NAME}:users" "/home/${U_NAME}" /opt/qBittorrent

unset U_NAME U_ID G_ID
