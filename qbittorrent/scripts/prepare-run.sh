#!/usr/bin/env bash

set -Eeuo pipefail

function ensure_user() {
	local U_ID=$1 U_NAME=$2 G_ID=$3
	if cat /etc/passwd | grep -- "$U_NAME" | grep -q -- ":$U_ID:$G_ID:"; then
		echo "Group $U_NAME exists with id $U_ID"
	else
		useradd --gid "$G_ID" --no-create-home --no-user-group --uid "$U_ID" "$U_NAME"
		echo "Created $U_NAME."
	fi
}

function ensure_group() {
	local G_ID=$1 G_NAME=$2
	if cat /etc/group | grep -- "$G_NAME" | grep -q -- ":$G_ID:"; then
		echo "Group $G_NAME exists with id $G_ID"
	else
		groupadd -g "$G_ID" "$G_NAME"
		echo "Created $G_NAME."
	fi
}

ensure_group 100 users
ensure_user 100 media_rw 100

mkdir -p /home/media_rw
chown media_rw:users /home/media_rw

echo 'LANG="zh_CN.utf8"' >/etc/locale.conf

systemctl enable dhclient dhclient6 xvnc0 i3 privoxy nginx update-self-ip update-self-ip.timer
systemctl enable qbittorrent

mkdir -p /etc/systemd/system/console-getty.service.d
echo '[Service]
Type=simple
ExecStart=
ExecStart=-/usr/bin/bash --login
StandardInput=tty
StandardOutput=tty
' >/etc/systemd/system/console-getty.service.d/override.conf

echo '[Journal]
Storage=volatile
RuntimeMaxUse=10M
' >/etc/systemd/journald.conf
