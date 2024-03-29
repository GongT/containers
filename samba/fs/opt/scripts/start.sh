#!/usr/bin/env bash

set -Eeuo pipefail

function create_config() {
	cat /opt/scripts/global.txt

	echo -n "interfaces = "
	echo $(ls /sys/class/net)

	echo "netbios name = $(< /etc/hostname)"

	for I in /mountpoints/*/; do
		create_section "$I"
	done
	for I in /drives/*/; do
		create_section "$I"
	done
}

function create_section() {
	local T_PATH="$1" OPTIONS LABEL
	local LABEL_FILE="${I}/.\$samba/disk label.txt"
	if [[ -e "$LABEL_FILE" ]]; then
		LABEL=$(< "$LABEL_FILE")
	else
		LABEL="$(basename "${T_PATH}")"
		if [[ "$LABEL" = "shm" ]]; then
			LABEL="System Memory"
		fi
		mkdir -p "$(dirname "$LABEL_FILE")"
		echo "$LABEL" > "$LABEL_FILE"
	fi

	local OPTIONS_FILE="${I}/.\$samba/samba options.txt"
	if [[ -e "$OPTIONS_FILE" ]]; then
		OPTIONS="$(echo $(< "$OPTIONS_FILE"))"
	else
		OPTIONS="acl_xattr"
		mkdir -p "$(dirname "$OPTIONS_FILE")"
		echo "acl_xattr" > "$OPTIONS_FILE"
	fi

	echo "
[$(basename "${T_PATH}")]
comment = ${LABEL}
path = ${T_PATH}/
vfs objects = $OPTIONS
recycle:repository = ${T_PATH}/.\$samba/recycle/%U
"
	cat /opt/scripts/section.txt
}

create_config > /etc/samba/smb.conf

if ! [[ -f /opt/config/username.map ]]; then
	touch /opt/config/username.map
fi
if ! [[ -f /opt/config/users ]]; then
	touch /opt/config/users
fi

create-all-user media_rw "$DEFAULT_PASSWORD"

touch /etc/samba/username.map.generate
while IFS= read -r LINE; do
	USERNAME="${LINE%%:*}"
	PASSWORD="${LINE#*:}"
	echo "User: $USERNAME, Password: $PASSWORD"
	if [[ "$PASSWORD" == "$DEFAULT_PASSWORD" ]]; then
		echo "media_rw = $USERNAME" >> /etc/samba/username.map.generate
	else
		ESCAPE_NAME="${USERNAME/@/_}"
		if [[ "$ESCAPE_NAME" != "$USERNAME" ]]; then
			echo "    Escaped: $ESCAPE_NAME"
			echo "$ESCAPE_NAME = $USERNAME" >> /etc/samba/username.map.generate
		fi
		create-all-user "$ESCAPE_NAME" "$PASSWORD"
	fi
done < "/opt/config/users"

/usr/lib/systemd/systemd-networkd-wait-online --interface=eth0 --timeout=10 || true
