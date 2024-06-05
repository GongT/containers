#!/usr/bin/env bash

set -Eeuo pipefail

function ensure_user() {
	local U_ID=$1 U_NAME=$2 G_ID=$3
	if grep -q -- "$U_NAME" /etc/passwd; then
		echo "Group $U_NAME exists: $(grep -- "$U_NAME" /etc/passwd)"
		usermod --gid "$G_ID" --uid "$U_ID" "$U_NAME"
	else
		useradd --gid "$G_ID" --no-create-home --no-user-group --uid "$U_ID" "$U_NAME"
		echo "Created $U_NAME."
	fi
}

function ensure_group() {
	local G_ID=$1 G_NAME=$2
	if grep -q -- "$G_NAME" /etc/group; then
		echo "Group $G_NAME exists: $(grep -- "$G_NAME" /etc/group)"
		groupmod -g "$G_ID" "$G_NAME"
	else
		groupadd -g "$G_ID" "$G_NAME"
		echo "Created group $G_NAME."
	fi
}

ensure_group 100 users
ensure_user 100 media_rw 100

mkdir -p /home/media_rw
chown media_rw:users /home/media_rw

mkdir -p /root/.config
touch /root/.config/user-dirs.dirs

systemctl enable transmission-daemon.service systemd-networkd.service chown-data.service
